Marty = require 'marty'
React = require 'react'

Page = require './views/page.cjsx'

class Application extends Marty.Application
    constructor: (options) ->
        super options

        # TODO http://martyjs.org/guides/application/automatic-registration.html
        @register 'navigationStore', require './stores/navigation.coffee'
        @register 'navigationActions', require './actions/navigation.coffee'
        #@createActions 'navigation', require './actions/navigation.coffee'
        #@createActions 'poi', require './actions/poi.coffee'
        #@createActions 'map', require './actions/map.coffee'
        #@createActions 'log', require './actions/log.coffee'

        #@createStore 'navigation', require('./stores/navigation.coffee'), this
        #@createStore 'poi', require('./stores/poi.coffee'), this
        #@createStore 'map', require('./stores/map.coffee'), this
        #@createStore 'log', require('./stores/log.coffee'), this

app = new Application()

React.render React.createElement(Marty.ApplicationContainer, {app}, React.createElement(Page)), document.body
