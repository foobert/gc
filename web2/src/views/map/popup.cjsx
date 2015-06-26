React = require 'react'

module.exports = React.createClass
    render: ->
        <div className="ui list">
            <div className="item">
                <div className="content">
                    <a className="header" href="http://coord.info/#{@props.Code}" target="_blank">{@props.Code}</a>
                    <div className="description">{@props.Name}</div>
                </div>
            </div>
            <div className="item">
                <div className="content">
                    <i className="location arrow icon"></i>
                    <Coordinates lat={@props.Latitude} lon={@props.Longitude}/>
                </div>
            </div>
            <div className="item">
                <div className="content">
                    <i className="suitcase icon"></i>
                    {@props.ContainerType.ContainerTypeName} {geocaches.names[@props.CacheType.GeocacheTypeId]}
                </div>
            </div>
            <div className="item">
                <div className="content">
                    <i className="signal icon"></i>
                    Difficulty {@props.Difficulty.toFixed 1}, Terrain {@props.Terrain.toFixed 1}
                </div>
            </div>
        </div>
