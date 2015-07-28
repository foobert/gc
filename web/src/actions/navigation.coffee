Marty = require 'marty'
Constants = require '../constants.coffee'

NavigationActions = Marty.createActionCreators
    navigate: (page, pushState = true) ->
        console.log 'inside navigate'
        console.log this, this.prototype
        page or= ''
        history.pushState page, page, "/#{page}" if pushState
        @dispatch Constants.NAVIGATE_PAGE, page

module.exports = NavigationActions
