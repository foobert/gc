{Actions} = require 'flummox'

class MapActions extends Actions
    setCenter: (center) ->
        center

    setZoom: (zoom) ->
        zoom

    setType: (ev) ->
        type: ev.target.id.substring 5
        action: if ev.target.checked then 'add' else 'remove'

    addUser: (username) ->
        username

    removeUser: (username) ->
        username

module.exports = MapActions
