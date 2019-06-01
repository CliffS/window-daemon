Util  = require 'util'
Child = require 'child_process'
Exec  = Util.promisify Child.execFile
Window = require './Window'

WM = 'wmctrl'

class WMctrl

  constructor: ->
    try
      retval = Child.execFileSync WM, ['-d']
    catch err
      console.error "Executable #{WM} not found in path"
      process.exit 1

  currentWindows: ->
    Exec WM, ['-lpG'], encoding: 'utf8'
    .then (output) =>
      lines = output.stdout.split '\n'
      windows = ( Window.parse line for line in lines when line isnt "" )








module.exports = WMctrl
