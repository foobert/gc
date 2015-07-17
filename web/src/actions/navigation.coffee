{Actions} = require 'flummox'

class NavigationActions extends Actions
    setPage: (page) ->
        console.log "set page #{page}"
        history.pushState {}, page, "/#{page}"
        page

module.exports = NavigationActions
