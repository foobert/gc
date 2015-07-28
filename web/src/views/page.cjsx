require 'semantic-ui-css/components/reset.css'
require 'semantic-ui-css/components/site.css'
require '../../css/index.css'

Marty = require 'marty'
React = require 'react'
MainMenu = require './main-menu.cjsx'
#PoiGenerator = require './poi-generator.cjsx'
#Map = require './map.cjsx'
#LogCalculator = require './log-calculator.cjsx'

Foo = React.createClass
    render: ->
        <div>foo</div>

Page = React.createClass
    componentDidMount: ->
        window.onpopstate = (ev) =>
            page = ev.state
            @props.navigatePage page, false

    render: ->
        #child = switch @props.page
            #when 'poi' then PoiGenerator
            #when 'map' then Map
            #when 'log' then LogCalculator
            #else PoiGenerator
        child = Foo

        <div className="container">
            <MainMenu page={@props.page} app={@props.app}/>
            <div className="content">
                { React.createElement child }
            </div>
        </div>

module.exports = Marty.createContainer Page,
    listenTo: 'navigationStore'
    fetch:
        page: -> @app.navigationStore.page
