React = require 'react'

module.exports = React.createClass
    render: ->
        <li className="item user">
            <i className="middle aligned red remove circle icon" data-username={@props.username} onClick={@props.remove}></i>
            <div className="content">
                {@props.username}
            </div>
        </li>
