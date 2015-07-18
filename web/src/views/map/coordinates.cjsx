React = require 'react'

module.exports = React.createClass
    _format: (coord, pos, neg) ->
        deg = Math.floor coord
        min = (coord - deg) * 60
        prefix = if coord < 0 then neg else pos
        "#{prefix} #{deg}\u00b0 #{min.toFixed 3}"

    shouldComponentUpdate: (nextProps, nextState) ->
        nextProps.lat? and (nextProps.lon? or nextProps.lng?)

    render: ->
        <span>{@_format @props.lat, 'N', 'S'} {@_format (@props.lon or @props.lng), 'E', 'W'}</span>
