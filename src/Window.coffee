

class Window

  constructor: (object = {}) ->
    @[k] = val for k, val of object

  @parse: (line) ->
    items = line.split /\s+/
    title = line.replace /^(?:\S+\s+){8}(.*?)\s*$/, '$1'
    new Window
      id:         Number.parseInt items[0]
      desktop:    Number.parseInt items[1]
      pid:        Number.parseInt items[2]
      position:
        x:        Number.parseInt items[3]
        y:        Number.parseInt items[4]
        width:    Number.parseInt items[5]
        height:   Number.parseInt items[6]
      machine:    items[7]
      title:      title

  compare: (other) ->
    throw new Error "Wrong type" unless other instanceof Window
    return false unless other.desktop is @desktop
    for i in ['x', 'y', 'width', 'height']
      return false unless other.position[i] is @position[i]
    return true


module.exports = Window
