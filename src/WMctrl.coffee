Util  = require 'util'
Child = require 'child_process'
Exec  = Util.promisify Child.execFile
Window = require './Window'

WM = 'wmctrl'

class WMctrl

  execute: (parameters) ->
    Exec WM, parameters
    .catch (err) =>
      console.error err
      process.exit 1

  desktops: ->
    try
      retval = Child.execFileSync WM, ['-d']
    catch err
      console.error "Executable #{WM} not found in path"
      process.exit 1

  currentWindows: ->
    @execute ['-lpG']
    .then (output) =>
      lines = output.stdout.split '\n'
      windows = ( Window.parse line for line in lines when line isnt "" )

  moveWindow: (id, desktop, position) ->
    id = ['-i', '-r', "0x#{id.toString(16)}" ]
    pos = [
      0
      position.x ? -1
      position.y ? -1
      position.width ? -1
      position.height ? -1
    ]
    pos = pos.join ','
    @execute [id..., '-t', desktop]
    .then =>
      @execute [id..., '-e', pos]




module.exports = WMctrl
