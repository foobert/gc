_ = require 'lodash'
Immutable = require 'immutable'
Store = require 'flummox-localstore'

geocaches = require '../geocache.coffee'

class MapStore extends Store
    constructor: (flux) ->
        super flux,
            initialState:
                center: [52.518769, 13.404027] # somewhere in Berlin
                zoom: 13
                selectedTypes: Immutable.Set.fromKeys geocaches.types
                filterUsers: Immutable.Set()
                locating: false
                locatingError: null
            serializer: (state) ->
                _.omit state, ['locating', 'locatingError']

        # HACK
        @state.selectedTypes = Immutable.Set @state.selectedTypes
        @state.filterUsers = Immutable.Set @state.filterUsers

        actions = flux.getActions 'map'
        @register actions.setCenter, @handleCenter
        @register actions.setZoom, @handleZoom
        @register actions.setType, @handleTypeFilter
        @register actions.addUser, @handleAddUser
        @register actions.removeUser, @handleRemoveUser
        @registerAsync actions.geolocate, @handleGeolocateBegin, @handleGeolocateSuccess, @handleGeolocateFail

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

    handleGeolocateBegin: ->
        @setState
            locating: true
            locatingError: null

    handleGeolocateSuccess: (position) ->
        @setState
            center: [position.coords.latitude, position.coords.longitude]
            locating: false
            locatingError: null

    handleGeolocateFail: (err) ->
        @setState
            locating: false
            locatingError: err.message

module.exports = MapStore
