{Store} = require 'marty'
Constants = require '../constants.coffee'

class NavigationStore extends Store
    constructor: (options) ->
        super options

        page = if window.location.pathname.length > 1
            window.location.pathname.substring 1
        else if window.location.hash?
            window.location.hash.substring 1
        else
            'poi'

        @state =
            page: page

        @handlers =
            navigatePage: Constants.NAVIGATE_PAGE

    navigatePage: (page) ->
        console.log "store setpage #{page}"
        @setState
            page: page

module.exports = NavigationStore
