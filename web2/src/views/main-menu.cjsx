React = require 'react'

module.exports = React.createClass
    displayName: 'MainMenu'
    render: ->
        active = (id) =>
            if @props.page is id
                'active item'
            else
                'item'

        <div className="ui left thin vertical inverted icon labeled sidebar menu">
            <div className="header item">
                <i className="green home icon"></i>
                Cache Cache
            </div>
            <a className={active 'poi'} onClick={=> @props.setPage 'poi'}>
                <i className="marker icon"></i>
                POI Generator
            </a>
            <a className={active 'map'} onClick={=> @props.setPage 'map' }>
                <i className="world icon"></i>
                Geocache Map
            </a>
            <a className={active 'track'}>
                <i className="sort content ascending icon"></i>
                Track Analysis
            </a>
            <a className={active 'statistics'}>
                <i className="line chart icon"></i>
                Statistics
            </a>
        </div>
