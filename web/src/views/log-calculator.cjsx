require 'semantic-ui-css/components/header.css'
require 'semantic-ui-css/components/form.css'
require 'semantic-ui-css/components/list.css'
require 'semantic-ui-css/components/message.css'

classnames = require 'classnames'
FluxComponent = require 'flummox/component'
React = require 'react'

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
    render: ->
        <div className="item">
            <span className="header">
                <a href="https://www.geocaching.com/geocache/#{@props.gc.Code}">{@props.gc.Code}</a> - {@props.gc.Name}
            </span>
            <div className="description">
                Found near <Coordinates lat={@props.gc.Latitude} lon={@props.gc.Longitude}/> at {new Date(@props.gc._timestamp).toString()}
            </div>
        </div>

ResultList = React.createClass
    render: ->
        return false unless @props.geocaches.length > 0

        <div className="result">
            <p>Identified {@props.geocaches.length} possible Geocaches:</p>
            <div className="ui list">
                {React.createElement(Geocache, gc: gc, key: gc.Code) for gc in @props.geocaches}
            </div>
        </div>

LogCalculator = React.createClass
    render: ->
        <div className="log-generator">
            <h1 className="ui header dividing">Log Generator</h1>
            <div className="ui warning message">
                <div className="header">Experimental!</div>
                <p>This feature is still highly experimental!</p>
                <p>The uploaded file is only processed inside your browser. Data sent to the server includes the approximate area where you may have searched for a Geocache.</p>
            </div>
            <FileDrop {...@props}/>
            <ResultList geocaches={@props.geocaches}/>
        </div>

module.exports = React.createClass
    render: ->
        <FluxComponent connectToStores={['log']}>
            <LogCalculator/>
        </FluxComponent>
