{Store} = require 'flummox'

class NavigationStore extends Store
    constructor: (flux) ->
        super flux

        @register flux.getActions('navigation').setPage, @handlePage

        @state =
            page: 'poi'


    handlePage: (page) ->
        @setState
            page: page

module.exports = NavigationStore
