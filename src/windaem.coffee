#!/usr/bin/env coffee

JSONdb = require 'node-json-db'
WMctrl = require './WMctrl'
Window = require './Window'
Path   = require 'path'
os     = require 'os'
fs     = require 'fs'

#CONFIG = Path.resolve os.homedir(), '.config/windaem.json'
CONFIGFILE  = Path.resolve __dirname,  '../data/config.json'
CONFIG      = null
CURRENT     = Path.resolve __dirname, '../data/windaem.json'
DB = new JSONdb CURRENT, true, true

loadConfig = ->
  Promise.resolve()
  .then =>
    fs.readFile CONFIGFILE, 'utf8', (err, data) =>
      try
        config = JSON.parse data
      catch err
        console.error "Reloading config file:"
        console.error err.message
        process.exit 1
      CONFIG = config

watchConfig = ->
  loadConfig()
  .then =>
    working = false
    fs.watch CONFIGFILE, (type, filename) =>
      unless working
        working = true
        setTimeout ->
          loadConfig()
          .then =>
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
  changed: changed
  created: created

fixWindow = (window) ->
  positions = CONFIG.positions
  search = window.title.toLowerCase()
  match = positions.find (item) =>
    title = item.title.toLowerCase()
    return false unless search.includes title
    return true
    if item.exact then window.title is item.title
  if match
    if match.first
      all = Object.values DB.getData "/windows"
      exact = match.exact
      search = if exact then window.title else window.title.toLowerCase()
      dupe = all.some (element) =>
        if exact
          element.title is search
        else
          title.toLowerCase().includes search
    unless dupe
      wm = new WMctrl
      wm.moveWindow window.id, match.desktop, match.position

main = ->
  watchConfig()
  saveCurrent()
  .then ->
    setInterval ->
      getCurrent()
      .then (windows) =>
        checkCurrent windows
      .then (result) =>
        for window in result.created
          fixWindow window
      .catch (err) =>
        console.error err
        process.exit 1
    , 1000


main()
