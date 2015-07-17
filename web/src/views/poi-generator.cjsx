require 'semantic-ui-css/components/button.css'
require 'semantic-ui-css/components/checkbox.css'
require 'semantic-ui-css/components/form.css'
require 'semantic-ui-css/components/header.css'
require 'semantic-ui-css/components/icon.css'
require 'semantic-ui-css/components/input.css'
require 'semantic-ui-css/components/label.css'
require 'semantic-ui-css/components/message.css'
require '../../css/poi.css'

FluxComponent = require 'flummox/component'
React = require 'react'
classnames = require 'classnames'

GeocacheTypeCheckbox = React.createClass
    render: ->
        <div className="field">
            <div className="ui input checkbox">
                <input
                    type="checkbox"
                    name="type"
                    id={@props.id}
                    checked={@props.selected}
                    onChange={@props.toggle}
                    />
                <label htmlFor={@props.id}>{@props.label}</label>
            </div>
        </div>

PoiGenerator = React.createClass
    componentWillMount: ->
        @actions = @props.flux.getActions('poi')

    getInitialState: ->
        types: [
            name: 'traditional', label: 'Traditional Geocache'
        ,
            name: 'multi', label: 'Multi Geocache'
        ,
            name: 'earth', label: 'Earthcache'
        ,
            name: 'letterbox', label: 'Letterbox'
        ,
            name: 'webcam', label: 'Webcam Geocache'
        ]

    render: ->
        classes = classnames
            ui: true
            form: true
            error: @props.error
            loading: @props.loading
            disabled: @props.loading

        <div className="poi-generator">
            <h1 className="ui header dividing">POI Generator</h1>
            <div className={classes}>
                <div className="ui error message">
                    <div className="header">Download Failed</div>
                    <p>Error something something.</p>
                </div>
                <div className="grouped fields">
                    <label>Geocache Types</label>
                    {@typeCheckbox t.name, t.label for t in @state.types}
                </div>
                <div className="field">
                    <label>Exclude finds by</label>
                    <input
                        type="text"
                        id="username"
                        placeholder="Username"
                        value={@props.username}
                        onChange={ (ev) => @actions.setUsername ev.target.value }
                    />
                </div>
                <div className="grouped fields">
                    <label htmlFor="format">File Format</label>
                    <div className="field">
                        <div className="ui input radio checkbox">
                            <input
                                type="radio"
                                name="format"
                                id="format-csv"
                                value="csv"
                                checked={if @props.format is 'csv' then 'checked' else null}
                                onChange={ (ev) => @actions.setFormat ev.target.value }
                            />
                            <label htmlFor="format-csv">CSV</label>
                        </div>
                    </div>
                    <div className="field">
                        <div className="ui radio checkbox">
                            <input
                                type="radio"
                                name="format"
                                id="format-gpx"
                                value="gpx"
                                checked={if @props.format is 'gpx' then 'checked' else null}
                                onChange={ (ev) => @actions.setFormat ev.target.value }
                            />
                            <label htmlFor="format-gpx">GPX</label>
                        </div>
                    </div>
                </div>
                <div className="ui submit labeled icon button" onClick={=> @actions.submit @props.format, @props.types}>
                    <i className="cloud download icon"></i>
                    Generate
                </div>
            </div>
        </div>

    typeCheckbox: (name, label) ->
        setType = @actions.setType.bind this, name
        id = "type-#{name}"
        <GeocacheTypeCheckbox
            id={id}
            key={id}
            label={label}
            selected={@props["type-#{name}"]}
            toggle={setType}
        />

module.exports = React.createClass
    render: ->
        <FluxComponent connectToStores={['poi']}>
            <PoiGenerator/>
        </FluxComponent>
