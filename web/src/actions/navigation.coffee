{Actions} = require 'flummox'

class NavigationActions extends Actions
    setPage: (page, pushState = true) ->
        page or= ''
        history.pushState page, page, "/#{page}" if pushState
        page

module.exports = NavigationActions
