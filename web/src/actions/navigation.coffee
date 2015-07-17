{Actions} = require 'flummox'

class NavigationActions extends Actions
    setPage: (page) ->
        history.pushState {}, page, "/#{page}"
        page

module.exports = NavigationActions
