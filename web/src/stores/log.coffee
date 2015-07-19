_ = require 'lodash'
Store = require 'flummox-localstore'

class LogStore extends Store
    constructor: (flux) ->
        super flux,
            initialState:
                geocaches: []
            serializer: (state) ->
                _.omit state, ['loading', 'error']

        actions = flux.getActions 'log'
        @registerAsync actions.uploadFile, @handleFileUploadBegin, @handleFileUploadSuccess, @handleFileUploadFail

    handleFileUploadBegin: (file) ->
        @setState
            parsing: true
            error: null
            geocaches: []

    handleFileUploadSuccess: (geocaches) ->
        @setState
            geocaches: geocaches
            parsing: false
            error: null

    handleFileUploadFail: (err) ->
        @setState
            parsing: false
            error: err

module.exports = LogStore
