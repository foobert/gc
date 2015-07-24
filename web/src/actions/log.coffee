{Actions} = require 'flummox'

parser = require './log/parser.js'

class LogActions extends Actions
    uploadFile: (file) ->
        parser file

    show: (gc) ->
        gc

module.exports = LogActions
