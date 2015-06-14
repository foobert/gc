Store = require 'flummox-localstore'

class MapStore extends Store
    constructor: (flux) ->
        super flux,
            initialState:
                center: [0, 0]
                zoom: 13

        actions = flux.getActions 'map'
        @register actions.setCenter, @handleCenter
        @register actions.setZoom, @handleZoom

    handleCenter: (center) ->
        @setState
            center: center

    handleZoom: (zoom) ->
        @setState
            zoom: zoom

module.exports = MapStore
