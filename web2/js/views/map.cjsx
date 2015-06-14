FluxComponent = require 'flummox/component'
L = require 'leaflet'
React = require 'react'

#require 'leaflet/dist/leaflet.css'
require '../../css/map.css'

Map = React.createClass
    displayName: 'Geocache Map'

    getInitialState: ->
        {}

    componentDidMount: ->
        @actions = @props.flux.getActions 'map'

        @icons = {}
        for id in [2, 3, 4, 5, 6, 8, 11, 13, 137, 453, 1858]
            @icons[id] = @createIcon id

        L.Icon.Default.imagePath = 'img/leaflet/'

        @map = L.map 'map',
            center: @props.center,
            zoom: @props.zoom

        L.tileLayer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            attribution: 'openstreetmap',
            maxZoom: 18
        .addTo @map

        @markerLayer = L.featureGroup([])
        @markerLayer.addTo @map

        @refreshMarkers()
        @map.on 'moveend', (ev) =>
            @refreshMarkers ev
            @actions.setZoom @map.getZoom()
            @actions.setCenter @map.getCenter()

    componentDidUpdate: (prevProps, prevState) ->
        if prevProps.center isnt @props.center
            @map.panTo @props.center

        if prevProps.zoom isnt @props.zoom
            @map.setZoom @props.zoom

        if prevProps.geocaches isnt @props.geocaches
            @markerLayer.clearLayers()
            for gc in @props.geocaches
                icon = @icons[gc.CacheType.GeocacheTypeId]
                marker = L.marker [gc.Latitude, gc.Longitude], {icon}
                marker.addTo @markerLayer

    componentWillUnmount: ->
        @actions.setZoom @map.getZoom()
        @actions.setCenter @map.getCenter()

    render: ->
        <div className="map-container">
            <div className="ui wide right visible sidebar">
                <div className="ui form">
                    <div className="grouped fields">
                        <label>Geocache Types</label>
                        <div className="field">
                            <div className="ui input checkbox">
                                <input
                                    type="checkbox"
                                    name="type"
                                    id="type-traditional"
                                    />
                                <label htmlFor="type-traditional">Traditiional</label>
                            </div>
                        </div>
                        <div className="field">
                            <div className="ui input checkbox">
                                <input
                                    type="checkbox"
                                    name="type"
                                    id="type-multi"
                                    />
                                <label htmlFor="type-multi">Multi</label>
                            </div>
                        </div>
                    </div>
                    <div className="field">
                        <label>Exclude finds by</label>
                        <input
                            type="text"
                            id="username"
                            placeholder="Username"
                        />
                    </div>
                </div>
            </div>
            <div id='map'></div>
        </div>

    refreshMarkers: ->
        @actions.setBounds @map.getBounds()

    createIcon: (id) ->
        L.icon
            iconUrl: "img/map/#{id}.gif"
            shadowUrl: null
            iconSize:     [32, 32] # size of the icon
            shadowSize:   [0, 0] # size of the shadow
            iconAnchor:   [16, 16] # point of the icon which will correspond to marker's location
            shadowAnchor: [0, 0]  # the same for the shadow
            popupAnchor:  [0, -16] # point from which the popup should open relative to the iconAnchor

module.exports = React.createClass
    render: ->
        <FluxComponent connectToStores={['map']}>
            <Map/>
        </FluxComponent>
