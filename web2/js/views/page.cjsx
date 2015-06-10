React = require 'react'
FluxComponent = require 'flummox/component'
MainMenu = require './main-menu.cjsx'
PoiGenerator = require './poi-generator.cjsx'

Menu = React.createClass
    displayName: 'Page'
    render: ->
        <div className="ui page">
            <MainMenu/>
            <PoiGenerator {... @props} />
        </div>

module.exports = React.createClass
    render: ->
        <FluxComponent flux=@props.flux connectToStores={['poi']}>
            <Menu {... @props}/>
        </FluxComponent>
