{Store} = require 'flummox'

class NavigationStore extends Store
    constructor: (flux) ->
        super flux

        @register flux.getActions('navigation').setPage, @handlePage

        page = if window.location.pathname.length > 1
            window.location.pathname.substring 1
        else if window.location.hash?
            window.location.hash.substring 1
        else
            'poi'

        @state =
            page: page

    handlePage: (page) ->
        @setState
            page: page

module.exports = NavigationStore
