#!/usr/bin/env coffee

JSONdb = require 'node-json-db'
WMctrl = require './WMctrl'
Window = require './Window'
Path   = require 'path'
os     = require 'os'
fs     = require 'fs'

#CONFIG = Path.resolve os.homedir(), '.config/windaem.json'
CONFIGFILE  = Path.resolve __dirname,  '../data/config.json'
CONFIG      = require CONFIGFILE
CURRENT     = Path.resolve __dirname, '../data/windaem.json'
DB = new JSONdb CURRENT, true, true

watchConfig = ->
  working = false
  fs.watch CONFIGFILE, (type, filename) =>
    unless working
      working = true
      setTimeout ->
        fs.readFile CONFIGFILE, 'utf8', (err, data) =>
          try
            CONFIG = JSON.parse data
          catch err
            console.error "Reloading config file:"
            console.error err.message
            process.exit 1
          working = false
      , 1000

getCurrent = ->
  wm = new WMctrl
  wm.currentWindows()

saveCurrent = ->
  wm = new WMctrl
  wm.currentWindows()
  .then (windows) =>
    DB.push "/windows", {}
    DB.push "/windows/#{window.id}", window for window in windows
    windows

  .catch (err) =>
    console.error err

checkCurrent = (windows) ->
  changed = []
  created = []
  for window in windows
    try
      old = new Window DB.getData "/windows/#{window.id}"
      changed.push window unless window.compare old
    catch
      created.push window
    finally
      DB.push "/windows/#{window.id}", window
  onDB = Object.keys(DB.getData "/windows").length
  if onDB > windows.length
    for item of DB.getData "/windows"
      do (item) =>
        DB.delete "/windows/#{item}" unless windows.some (element) =>
          element.id.toString() is item
  console.log onDB, Object.keys(DB.getData "/windows").length
  changed: changed
  created: created

main = ->
  watchConfig()
  saveCurrent()
  .then ->
    setInterval ->
      getCurrent()
      .then (windows) =>
        checkCurrent windows
      .then (result) =>
        console.log result if result.changed.length or result.created.length
      .catch (err) =>
        console.error err
        process.exit 1
    , 1000


main()
