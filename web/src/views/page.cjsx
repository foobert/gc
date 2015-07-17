require 'semantic-ui-css/components/reset.css'
require 'semantic-ui-css/components/site.css'
require '../../css/index.css'

React = require 'react'
FluxComponent = require 'flummox/component'
MainMenu = require './main-menu.cjsx'
PoiGenerator = require './poi-generator.cjsx'
Map = require './map.cjsx'

Page = React.createClass
    componentWillMount: ->
        @actions = @props.flux.getActions 'navigation'

    render: ->
        child = switch @props.page
            when 'poi' then PoiGenerator
            when 'map' then Map
            else PoiGenerator

        <div className="container">
            <MainMenu page={@props.page} setPage={@actions.setPage}/>
            <div className="content">
                { React.createElement child }
            </div>
        </div>

module.exports = React.createClass
    render: ->
        <FluxComponent flux=@props.flux connectToStores={['navigation']}>
            <Page/>
        </FluxComponent>
