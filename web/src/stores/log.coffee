_ = require 'lodash'
Store = require 'flummox-localstore'

class LogStore extends Store
    constructor: (flux) ->
        super flux,
            initialState:
                geocaches: null
            serializer: (state) ->
                _.omit state, ['parsing', 'error']

        actions = flux.getActions 'log'
        @registerAsync actions.uploadFile, @handleFileUploadBegin, @handleFileUploadSuccess, @handleFileUploadFail

    handleFileUploadBegin: (file) ->
        @setState
            parsing: true
            error: null
            geocaches: null

    handleFileUploadSuccess: (geocaches) ->
        @setState
            geocaches: geocaches
            parsing: false
            error: null

    handleFileUploadFail: (err) ->
        @setState
            parsing: false
            error: err
            geocaches: null

module.exports = LogStore
