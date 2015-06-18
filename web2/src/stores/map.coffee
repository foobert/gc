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
                filterUsers: Immutable.Set()

        # HACK
        @state.selectedTypes = Immutable.Set @state.selectedTypes
        @state.filterUsers = Immutable.Set @state.filterUsers

        actions = flux.getActions 'map'
        @register actions.setCenter, @handleCenter
        @register actions.setZoom, @handleZoom
        @register actions.setType, @handleTypeFilter
        @register actions.addUser, @handleAddUser
        @register actions.removeUser, @handleRemoveUser

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

    handleAddUser: (username) ->
        @setState filterUsers: @state.filterUsers.add username

    handleRemoveUser: (username) ->
        @setState filterUsers: @state.filterUsers.remove username


module.exports = MapStore
