React = require 'react'

module.exports = React.createClass
    render: ->
        <div className="field">
            <div className="ui input checkbox">
                <input
                    type="checkbox"
                    name="type"
                    id="type-#{@props.id}"
                    checked={@props.selected?.has @props.id}
                    onChange={@props.toggle}
                    />
                <label htmlFor="type-#{@props.id}">{@props.label}</label>
            </div>
        </div>
