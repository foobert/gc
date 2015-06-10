require '../css/index.css'

_ = require 'lodash'
{Actions, Flummox} = require 'flummox'
Store = require 'flummox-localstore'
Promise = require 'bluebird'

class PoiActions extends Actions
    setType: (typeId) ->
        typeId

    setFormat: (format) ->
        format

    setUsername: (username) ->
        username

    submit: (types) ->
        new Promise (resolve, reject) ->
            files = types.map (type) ->
                url: "https://gc.funkenburg.net/api/poi.csv?type=#{type}"
                name: "#{type}.csv"
            JSZip = require 'jszip'
            zip = new JSZip()
            zipFolder = zip.folder 'poi'
            h = (name, data) ->
                if data?
                    zipFolder.file name, data
                if files.length is 0
                    zipBlob = zip.generate type: 'blob'
                    {saveAs} = require 'node-safe-filesaver'
                    saveAs zipBlob, 'poi.zip'
                    resolve()
                else
                    next = files.shift()
                    $.get next.url
                        .done (data) -> h next.name, data
                        .fail ->
                            reject(new Error('download failed'))
            h()

        ###
        zip = new JSZip()
        zipFolder = zip.folder 'poi'
        for type in types
            url = "https://gc.funkenburg.net/api/poi.csv?type=#{type}"
            name = "#{type}.csv"
            [response, body] = yield request.get url
            if response.statusCode is 200
                zipFolder.file name, body
            else
                throw new Error "Download of #{name} failed: #{response.statusCode}"
        zipBlob = zip.generate type: 'blob'
        saveAs zipBlob, 'poi.zip'
        ###

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
            serializer: (state) ->
                _.omit state, ['loading', 'error']

        actions = flux.getActions 'poi'
        @register actions.setType, @handleType
        @register actions.setFormat, @handleFormat
        @register actions.setUsername, @handleUsername
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

    handleSubmitBegin: ->
        @setState
            loading: true

    handleSubmitSuccess: ->
        @setState
            loading: false
            error: false
            username: null

    handleSubmitFail: ->
        @setState
            loading: false
            error: true

class Flux extends Flummox
    constructor: ->
        super()

        @createActions 'poi', PoiActions
        @createStore 'poi', PoiStore, this

flux = new Flux()

React = require 'react'
Page = require './views/page.cjsx'
React.render React.createElement(Page, {
    flux: flux
    setType: flux.getActions('poi').setType
    setFormat: flux.getActions('poi').setFormat
    setUsername: flux.getActions('poi').setUsername
    submit: flux.getActions('poi').submit
}), document.body
