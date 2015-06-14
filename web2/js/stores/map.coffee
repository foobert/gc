_ = require 'lodash'
Store = require 'flummox-localstore'

class MapStore extends Store
    constructor: (flux) ->
        super flux,
            initialState:
                center: [0, 0]
                zoom: 13
                geocaches: []
                error: null
            serializer: (state) ->
                _.omit state, ['geocaches', 'error']

        actions = flux.getActions 'map'
        @register actions.setCenter, @handleCenter
        @register actions.setZoom, @handleZoom
        @registerAsync actions.setBounds, @handleBoundsBegin, @handleBoundsSuccess, @handleBoundsFail

    handleCenter: (center) ->
        @setState
            center: center

    handleZoom: (zoom) ->
        @setState
            zoom: zoom

    handleBoundsBegin: (bounds) ->
        # nop

    handleBoundsSuccess: (geocaches) ->
        @setState
            geocaches: geocaches
            error: null

    handleBoundsFail: (err) ->
        @setState
            error: err

module.exports = MapStore
