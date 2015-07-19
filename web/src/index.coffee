{Flummox} = require 'flummox'
React = require 'react'

Page = require './views/page.cjsx'

class Flux extends Flummox
    constructor: ->
        super()

        @createActions 'poi', require './actions/poi.coffee'
        @createActions 'navigation', require './actions/navigation.coffee'
        @createActions 'map', require './actions/map.coffee'
        @createActions 'log', require './actions/log.coffee'

        @createStore 'poi', require('./stores/poi.coffee'), this
        @createStore 'navigation', require('./stores/navigation.coffee'), this
        @createStore 'map', require('./stores/map.coffee'), this
        @createStore 'log', require('./stores/log.coffee'), this

flux = new Flux()
React.render React.createElement(Page, {flux}), document.body
