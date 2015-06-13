L = require 'leaflet'
React = require 'react'

#require 'leaflet/dist/leaflet.css'
require '../../css/map.css'

module.exports = React.createClass
    displayName: 'Geocache Map'

    componentDidMount: ->
        map = L.map 'map',
            center: [51.505, -0.09],
            zoom: 13
        L.tileLayer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            attribution: 'openstreetmap',
            maxZoom: 18
        .addTo map

    render: ->
        <div className="map-container">
            <div id='map'></div>
        </div>
