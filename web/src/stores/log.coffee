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
        @register actions.show, @handleShow
        @registerAsync actions.uploadFile, @handleFileUploadBegin, @handleFileUploadSuccess, @handleFileUploadFail

    handleShow: (geocache) ->
        @setState
            center: [geocache.Latitude, geocache.Longitude]

    handleFileUploadBegin: (file) ->
        @setState
            parsing: true
            error: null
            geocaches: null
            track: null

    handleFileUploadSuccess: ({geocaches, track}) ->
        @setState
            geocaches: geocaches
            track: track
            parsing: false
            error: null

    handleFileUploadFail: (err) ->
        @setState
            parsing: false
            error: err
            geocaches: null
            track: null

module.exports = LogStore
