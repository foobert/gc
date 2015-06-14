L = require 'leaflet'
React = require 'react'
jquery = require 'jquery'

#require 'leaflet/dist/leaflet.css'
require '../../css/map.css'

module.exports = React.createClass
    displayName: 'Geocache Map'

    getInitialState: ->
        {}

    componentDidMount: ->
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

        @actions = @props.flux.getActions 'map'

    componentDidUpdate: (prevProps, prevState) ->
        if @prevProps.center isnt @props.center
            @map.panTo @props.center
        if @prevProps.zoom isnt @props.zoom
            @map.setZoom @props.zoom

    componentWillUnmount: ->
        @actions.setZoom @map.getZoom()
        @actions.setCenter @map.getCenter()

    render: ->
        <div className="map-container">
            <div id='map'></div>
        </div>

    refreshMarkers: ->
        bounds = @map.getBounds()
        minll = bounds.getSouthWest()
        maxll = bounds.getNorthEast()

        url = 'https://gc.funkenburg.net/api'
        url += "/geocaches?excludeDisabled=1&bounds[]=#{minll.lat}&bounds[]=#{minll.lng}&bounds[]=#{maxll.lat}&bounds[]=#{maxll.lng}"

        jquery.get url
            .done (geocaches) =>
                @markerLayer.clearLayers()
                for gc in geocaches
                    icon = @icons[gc.CacheType.GeocacheTypeId]
                    marker = L.marker [gc.Latitude, gc.Longitude], {icon}
                    marker.addTo @markerLayer

    createIcon: (id) ->
        L.icon
            iconUrl: "img/map/#{id}.gif"
            shadowUrl: null
            iconSize:     [32, 32] # size of the icon
            shadowSize:   [0, 0] # size of the shadow
            iconAnchor:   [16, 16] # point of the icon which will correspond to marker's location
            shadowAnchor: [0, 0]  # the same for the shadow
            popupAnchor:  [0, -16] # point from which the popup should open relative to the iconAnchor
