_ = require 'lodash'
Immutable = require 'Immutable'
Store = require 'flummox-localstore'

class MapStore extends Store
    constructor: (flux) ->
        super flux,
            initialState:
                center: [0, 0]
                zoom: 13
                selectedTypes: Immutable.Set()

        # HACK
        @state.selectedTypes = Immutable.Set @state.selectedTypes

        actions = flux.getActions 'map'
        @register actions.setCenter, @handleCenter
        @register actions.setZoom, @handleZoom
        @register actions.setType, @handleTypeFilter

    handleCenter: (center) ->
        @setState
            center: center

    handleZoom: (zoom) ->
        @setState
            zoom: zoom

    handleTypeFilter: ({type, action}) ->
        if action is 'add'
            @setState selectedTypes: @state.selectedTypes.add type
        else
            @setState selectedTypes: @state.selectedTypes.remove type


module.exports = MapStore
