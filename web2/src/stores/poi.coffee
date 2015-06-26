_ = require 'lodash'
Store = require 'flummox-localstore'

class PoiStore extends Store
    constructor: (flux) ->
        super flux,
            initialState:
                "type-traditional": true
                "type-multi": true
                "type-earth": true
                "type-letterbox": true
                "type-webcam": true
                format: 'csv'
                types: ['traditional', 'multi', 'earth', 'letterbox', 'webcam']
                loading: false
                error: false
                filename: null
            serializer: (state) ->
                _.omit state, ['loading', 'error', 'filename']

        actions = flux.getActions 'poi'
        @register actions.setType, @handleType
        @register actions.setFormat, @handleFormat
        @register actions.setUsername, @handleUsername
        @register actions.setFilename, @handleFilename
        @registerAsync actions.submit, @handleSubmitBegin, @handleSubmitSuccess, @handleSubmitFail

    handleType: (typeId) ->
        newTypes = @state.types.slice()
        index = newTypes.indexOf typeId
        if index isnt -1
            newTypes.splice index, 1
        else
            newTypes.push typeId

        @setState
            "type-#{typeId}": not @state["type-#{typeId}"]
            types: newTypes

    handleFormat: (format) ->
        @setState
            format: format

    handleUsername: (username) ->
        @setState
            username: username

    handleFilename: (filename) ->
        @setState
            filename: filename

    handleSubmitBegin: ->
        @setState
            loading: true

    handleSubmitSuccess: ->
        @setState
            loading: false
            error: false

    handleSubmitFail: ->
        @setState
            loading: false
            error: true

module.exports = PoiStore
