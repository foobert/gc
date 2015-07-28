require 'semantic-ui-css/components/icon.css'
require 'semantic-ui-css/components/menu.css'
require 'semantic-ui-css/components/sidebar.css'
require '../../css/menu.css'

api = require '../backend.coffee'

React = require 'react'

module.exports = React.createClass
    displayName: 'MainMenu'
    render: ->
        active = (id) =>
            if @props.page is id
                'active item'
            else
                'item'
        # log calculator -> book icon
        # statistics -> bar chart icon

        <div className="ui left thin vertical inverted icon labeled sidebar menu">
            <div className="disabled header item">
                <i className="world icon"></i>
                Cache Cache
            </div>
            <a className={active 'poi'} onClick={=> @props.app.navigationActions.navigate 'poi'}>
                <i className="marker icon"></i>
                POI Generator
            </a>
            <a className={active 'map'} onClick={=> @props.app.navigationActions.navigate 'map' }>
                <i className="world icon"></i>
                Geocache Map
            </a>
            <a className={active 'log'} onClick={=> @props.app.navigationActions.navigate 'log' }>
                <i className="book icon"></i>
                Log Calculator
            </a>
            <a className="item" href={api.url '/feed'} target="_blank">
                <i className="feed icon"></i>
                Atom feed
            </a>
            <a className="item" href="https://github.com/foobert/gc" target="_blank">
                <i className="github icon"></i>
                View Source
            </a>
        </div>
