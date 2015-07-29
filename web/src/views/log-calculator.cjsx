require 'semantic-ui-css/components/button.css'
require 'semantic-ui-css/components/form.css'
require 'semantic-ui-css/components/header.css'
require 'semantic-ui-css/components/icon.css'
require 'semantic-ui-css/components/image.css'
require 'semantic-ui-css/components/item.css'
require 'semantic-ui-css/components/list.css'
require 'semantic-ui-css/components/message.css'

classnames = require 'classnames'
FluxComponent = require 'flummox/component'
L = require 'leaflet'
React = require 'react'
Popup = require './map/popup.cjsx'

require '../../css/log.css'

class FileDrop extends React.Component
    constructor: (props) ->
        super props
        @state = {}

    componentWillMount: ->
        @actions = @props.flux.getActions 'log'

    render: ->
        classes = classnames
            ui: true
            form: true
            loading: @props.parsing
            disabled: @props.parsing
            error: @props.error
        <div className={classes}>
            <div
                className="field"
                onDragLeave={@handleDragLeave.bind this}
                onDragOver={@handleDragOver.bind this}
                onDrop={@handleDrop.bind this}
            >
                <label>Upload GPX file</label>
                <input type="file" ref="fileInput" onChange={@handleFileChange.bind this}/>
            </div>
            <div className="ui error message">
                Something went wrong: {@props.error}
            </div>
        </div>

    handleDragLeave: ->
        @setState isDragOver: false if @state.isDragOver

    handleDragOver: (event) ->
        event.preventDefault()
        event.dataTransfer.effectAllowed = 'copy'
        event.dataTransfer.dropEffect = 'copy'
        @setState isDragOver: true if not @state.isDragOver

    handleDrop: (event) ->
        event.preventDefault()
        handleFiles event.dataTransfer.files

    handleFileChange: (even) ->
        input = React.findDOMNode @refs.fileInput
        @handleFiles input.files

    handleFiles: (files) ->
        return unless files? and files.length > 0

        console.log "dropped #{files.length} files"
        @setState
            files: files
            isDragOver: false
        for i in [0...files.length]
            @actions.uploadFile files[i]

Coordinates = require './map/coordinates.cjsx'

Geocache = React.createClass
    componentDidMount: ->
        @actions = @props.flux.getActions 'log'

    render: ->
        date = new Date(@props.gc._timestamp).toISOString()
        formattedDate = "#{date.slice 0, 10} #{date.slice 11, 16}"
        <div className="item" onClick={=> @actions.show @props.gc}>
            <div className="right floated content actions">
                <div className="ui mini basic button" onClick={=> @actions.show @props.gc}><i className="unhide icon"/>Show</div>
                <div className="ui mini basic button"><i className="external icon"/>Log</div>
            </div>
            <img className="ui avatar image" src={require "../../img/map/#{@props.gc.CacheType.GeocacheTypeId}.gif"}/>
            <div className="content">
                <p><a href="https://www.geocaching.com/geocache/#{@props.gc.Code}">{@props.gc.Code}</a> - {@props.gc.Name}</p>
                <p>{formattedDate}</p>
            </div>
        </div>

Map = React.createClass
    componentDidMount: ->
        @map = L.map 'map',
            zoomControl: false
            attributionControl: false
        L.tileLayer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            maxZoom: 18
        .addTo @map
        @overlay = L.featureGroup []
        @overlay.addTo @map
        @icons = {}
        for id in [2, 3, 4, 5, 6, 8, 11, 13, 137, 453, 1858]
            @icons[id] = @createIcon id
        @refreshMap()

    createIcon: (id) ->
        L.icon
            iconUrl: require "../../img/map/#{id}.gif"
            shadowUrl: null
            iconSize:     [32, 32] # size of the icon
            shadowSize:   [0, 0]   # size of the shadow
            iconAnchor:   [16, 16] # point of the icon which will correspond to marker's location
            shadowAnchor: [0, 0]   # the same for the shadow
            popupAnchor:  [0, -16] # point from which the popup should open relative to the iconAnchor

    componentDidUpdate: (prevProps, prevState) ->
        @refreshMap()

    refreshMap: ->
        @overlay.clearLayers()

        return unless @props.track?.length > 0

        @props.geocaches.forEach (geocache) =>
            icon = @icons[geocache.CacheType.GeocacheTypeId]
            marker = L.marker [geocache.Latitude, geocache.Longitude],
                icon: icon
                title: geocache.Code
            marker.on 'click', (e) =>
                popup = L.popup closeButton: false, offset: L.point(0, -5)
                    .setLatLng e.latlng
                    .setContent React.renderToStaticMarkup <Popup {... geocache}/>
                    .openOn @map
            marker.addTo @overlay

        track = L.polyline @props.track,
            color: '#ff0000'
            weight: 2
        track.addTo @overlay
        @map.fitBounds track.getBounds()
        @map.panTo @props.center

    render: ->
        classes = classnames
            map: true
            withResults: @props.track?.length > 0
        <div className={classes}>
            <div id="map"/>
        </div>

ResultList = React.createClass
    render: ->
        return false unless @props.geocaches?
        if @props.geocaches.length is 0
            return <div className="list">
                <p>No Geocaches could be found.</p>
            </div>

        <div className="list">
            <div className="ui list">
                {React.createElement(Geocache, flux: @props.flux, gc: gc, key: gc.Code) for gc in @props.geocaches}
            </div>
        </div>

LogCalculator = React.createClass
    render: ->
        <div className="log-generator">
            <h1 className="ui header dividing">Log Generator</h1>
            <div className="ui warning message">
                <div className="header">Experimental!</div>
                <p>This feature is still highly experimental! Use with care and don't trust the data.</p>
            </div>
            <p>
                You can use the log generator to analyse GPX tracks from your
                GPS device to identify possible Geocache finds. It will search
                for Geocaches near locations where you spent some time and list
                them below.
            </p>
            <p>
                The uploaded file is only processed inside your browser. Data
                sent to the server includes the approximate area where you may
                have searched for a Geocache.
            </p>
            <FileDrop {...@props}/>
            <div className="results">
                <ResultList {...@props}/>
                <Map {...@props}/>
            </div>
        </div>

module.exports = React.createClass
    render: ->
        <FluxComponent connectToStores={['log']}>
            <LogCalculator/>
        </FluxComponent>
