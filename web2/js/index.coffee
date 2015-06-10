require '../css/index.css'

{Flummox} = require 'flummox'
React = require 'react'

Page = require './views/page.cjsx'

class Flux extends Flummox
    constructor: ->
        super()

        @createActions 'poi', require './actions/poi.coffee'
        @createStore 'poi', require('./stores/poi.coffee'), this

flux = new Flux()
React.render React.createElement(Page, {
    flux: flux
    setType: flux.getActions('poi').setType
    setFormat: flux.getActions('poi').setFormat
    setUsername: flux.getActions('poi').setUsername
    submit: flux.getActions('poi').submit
}), document.body
