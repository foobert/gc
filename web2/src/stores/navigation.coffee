{Store} = require 'flummox'

class NavigationStore extends Store
    constructor: (flux) ->
        super flux

        @register flux.getActions('navigation').setPage, @handlePage

        if window.location.hash?
            page = window.location.hash.substring 1

        @state =
            page: page ? 'poi'


    handlePage: (page) ->
        @setState
            page: page

module.exports = NavigationStore
