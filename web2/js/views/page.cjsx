React = require 'react'
FluxComponent = require 'flummox/component'
MainMenu = require './main-menu.cjsx'
PoiGenerator = require './poi-generator.cjsx'
Map = require './map.cjsx'

Page = React.createClass
    displayName: 'Page'
    render: ->
        child = switch @props.page
            when 'poi' then PoiGenerator
            when 'map' then Map
            else PoiGenerator

        <div className="ui pushable">
            <MainMenu page={@props.page} setPage={@props.setPage}/>
            <div className="pusher">
                {React.createElement(child, React.__spread({}, @props))}
            </div>
        </div>

module.exports = React.createClass
    render: ->
        <FluxComponent flux=@props.flux connectToStores={['poi', 'navigation', 'map']}>
            <Page {... @props}/>
        </FluxComponent>
