{Actions} = require 'flummox'

class NavigationActions extends Actions
    setPage: (page) ->
        console.log "set page #{page}"
        page

module.exports = NavigationActions
