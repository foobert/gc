React = require 'react'

module.exports = React.createClass
    displayName: 'MainMenu'
    render: ->
        <div className="ui left visible vertical inverted labeled icon sidebar menu">
            <div className="header item">
                <i className="home icon"></i>
                Cache Cache
            </div>
            <a className="active item">
                <i className="marker icon"></i>
                POI Generator
            </a>
            <a className="item">
                <i className="world icon"></i>
                Geocache Map
            </a>
            <a className="item">
                <i className="sort content ascending icon"></i>
                Track Analysis
            </a>
            <a className="item">
                <i className="line chart icon"></i>
                Statistics
            </a>
        </div>
