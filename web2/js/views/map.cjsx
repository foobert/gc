L = require 'leaflet'
React = require 'react'

#require 'leaflet/dist/leaflet.css'
require '../../css/map.css'

module.exports = React.createClass
    displayName: 'Geocache Map'

    getInitialState: ->
        {}

    componentDidMount: ->
        map = L.map 'map',
            center: @props.center,
            zoom: @props.zoom
        L.tileLayer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            attribution: 'openstreetmap',
            maxZoom: 18
        .addTo map

        @state.map = map
        @state.actions = @props.flux.getActions 'map'

    componentDidUpdate: (prevProps, prevState) ->
        if @prevProps.center isnt @props.center
            @state.map.panTo @props.center
        if @prevProps.zoom isnt @props.zoom
            @state.map.setZoom @props.zoom

    componentWillUnmount: ->
        @state.actions.setZoom @state.map.getZoom()
        @state.actions.setCenter @state.map.getCenter()

    render: ->
        <div className="map-container">
            <div id='map'></div>
        </div>
