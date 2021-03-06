require 'semantic-ui-css/components/button.css'
require 'semantic-ui-css/components/checkbox.css'
require 'semantic-ui-css/components/form.css'
require 'semantic-ui-css/components/icon.css'
require 'semantic-ui-css/components/input.css'
require 'semantic-ui-css/components/label.css'
require 'semantic-ui-css/components/sidebar.css'
require 'leaflet/dist/leaflet.css'
require '../../css/map.css'

FluxComponent = require 'flummox/component'
L = require 'leaflet'
React = require 'react'
classnames = require 'classnames'
request = require 'superagent'

geocaches = require '../geocache.coffee'
server = require '../backend.coffee'

TypeFilter = require './map/type-filter.cjsx'
UserFilter = require './map/user-filter.cjsx'
Coordinates = require './map/coordinates.cjsx'
Popup = require './map/popup.cjsx'

Map = React.createClass
    displayName: 'Geocache Map'

    getInitialState: ->
        {}

    componentDidMount: ->
        @actions = @props.flux.getActions 'map'

        @icons = {}
        for id in [2, 3, 4, 5, 6, 8, 11, 13, 137, 453, 1858]
            @icons[id] = @createIcon id

        @map = L.map 'map',
            center: @props.center,
            zoom: @props.zoom

        L.tileLayer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            maxZoom: 18
        .addTo @map

        @markerLayer = L.featureGroup([])
        @markerLayer.addTo @map

        @map.on 'moveend', (ev) =>
            @actions.setZoom @map.getZoom()
            @actions.setCenter @map.getCenter()

        @refreshMap()

    componentDidUpdate: (prevProps, prevState) ->
        needsRefresh = false
        if prevProps.center isnt @props.center
            @map.panTo @props.center
            needsRefresh = true

        if prevProps.zoom isnt @props.zoom
            @map.setZoom @props.zoom
            needsRefresh = true

        if prevProps.selectedTypes isnt @props.selectedTypes
            needsRefresh = true

        if prevProps.filterUsers isnt @props.filterUsers
            needsRefresh = true

        @refreshMap() if needsRefresh

    componentWillUnmount: ->
        # TODO this will raise a cannot dispatch in the middle of a dispatch error
        #@actions.setZoom @map.getZoom()
        #@actions.setCenter @map.getCenter()

    refreshMap: ->
        _qs = (key, values) ->
            # superagent can't deal with arrays in query params :-(
            values
                .map (v) -> "#{key}[]=#{v}"
                .join '&'

        bounds = @map.getBounds()
        minll = bounds.getSouthWest()
        maxll = bounds.getNorthEast()
        typeIds = @props.selectedTypes.toArray().map @typeToId
        request
            .get server.url '/geocaches'
            .query excludeDisabled: 1
            .query _qs 'bounds', [minll.lat, minll.lng, maxll.lat, maxll.lng]
            .query _qs 'typeIds', typeIds
            .query _qs 'excludeFinds', @props.filterUsers.toArray()
            .end (err, res) =>
                if err or res.status isnt 200
                    return console.log "Geocache download failed (#{res?.status}): #{err}"

                @markerLayer.clearLayers()
                res.body.forEach (gc) =>
                    icon = @icons[gc.CacheType.GeocacheTypeId]
                    marker = L.marker [gc.Latitude, gc.Longitude],
                        icon: icon
                        title: gc.Code
                    marker.on 'click', (e) =>
                        popup = L.popup closeButton: false, offset: L.point(0, -5)
                            .setLatLng e.latlng
                            .setContent React.renderToStaticMarkup <Popup {... gc}/>
                            .openOn @map
                    marker.addTo @markerLayer

    typeToId: (type) ->
        geocaches.types[type]

    render: ->
        typeToggle = @props.flux.getActions('map').setType
        if navigator.geolocation?
            locateClasses = classnames
                ui: true
                button: true
                labeled: true
                icon: true
                loading: @props.locating
            locateButton = 
                <div className="locate">
                    <div className={locateClasses} onClick={@props.flux.getActions('map').geolocate}>
                        <i className="crosshairs icon"></i>
                        Center on me
                    </div>
                    <div className="error">{@props.locatingError}</div>
                </div>

        <div className="map-container">
            <div id='map'></div>
            <div className="ui right sidebar">
                <div className="ui form">
                    <div className="grouped fields">
                        <label>Geocache Types</label>
                        <TypeFilter
                            id="traditional" label="Traditional"
                            selected={@props.selectedTypes} toggle={typeToggle}/>
                        <TypeFilter
                            id="multi" label="Multi-Cache"
                            selected={@props.selectedTypes} toggle={typeToggle}/>
                        <TypeFilter
                            id="letterbox" label="Letterbox"
                            selected={@props.selectedTypes} toggle={typeToggle}/>
                        <TypeFilter
                            id="event" label="Event-Cache"
                            selected={@props.selectedTypes} toggle={typeToggle}/>
                        <TypeFilter
                            id="mystery" label="Mystery"
                            selected={@props.selectedTypes} toggle={typeToggle}/>
                        <TypeFilter
                            id="webcam" label="Webcam"
                            selected={@props.selectedTypes} toggle={typeToggle}/>
                        <TypeFilter
                            id="virtual" label="Virtual"
                            selected={@props.selectedTypes} toggle={typeToggle}/>
                        <TypeFilter
                            id="cito" label="Cache In Trash Out"
                            selected={@props.selectedTypes} toggle={typeToggle}/>
                        <TypeFilter
                            id="earth" label="Earth-Cache"
                            selected={@props.selectedTypes} toggle={typeToggle}/>
                        <TypeFilter
                            id="mega" label="Mega-Event"
                            selected={@props.selectedTypes} toggle={typeToggle}/>
                        <TypeFilter
                            id="wherigo" label="Wherigo"
                            selected={@props.selectedTypes} toggle={typeToggle}/>
                    </div>
                    <form onSubmit={@handleSubmit}>
                        <div className="grouped fields">
                            <label>Exclude finds</label>
                            <div className="ui action input">
                                <input
                                    type="text"
                                    id="username"
                                    placeholder="Username"
                                    ref="username"
                                />
                                <button className="ui icon button">
                                    <i className="plus icon"></i>
                                </button>
                            </div>
                            <ul className="ui list">
                                { React.createElement(UserFilter, key: username, username: username, remove: @handleRemoveUser) for username in @props.filterUsers.toArray() }
                            </ul>
                        </div>
                    </form>
                    <div className="grouped fields">
                        <label>Location</label>
                        <div>
                            <Coordinates {...@props.center} />
                        </div>
                        {locateButton}
                    </div>
                </div>
            </div>
        </div>

    handleSubmit: (ev) ->
        ev.preventDefault()
        textInput = React.findDOMNode @refs.username
        @props.flux.getActions('map').addUser textInput.value
        textInput.value = ''

    handleRemoveUser: (ev) ->
        ev.preventDefault()
        username = ev.target.getAttribute 'data-username'
        @props.flux.getActions('map').removeUser username

    createIcon: (id) ->
        L.icon
            iconUrl: require "../../img/map/#{id}.gif"
            shadowUrl: null
            iconSize:     [32, 32] # size of the icon
            shadowSize:   [0, 0]   # size of the shadow
            iconAnchor:   [16, 16] # point of the icon which will correspond to marker's location
            shadowAnchor: [0, 0]   # the same for the shadow
            popupAnchor:  [0, -16] # point from which the popup should open relative to the iconAnchor

module.exports = React.createClass
    render: ->
        <FluxComponent connectToStores={['map']}>
            <Map/>
        </FluxComponent>
