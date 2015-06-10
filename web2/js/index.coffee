require '../css/index.css'

{Actions, Store, Flummox} = require 'flummox'

class PoiActions extends Actions
    setType: (typeId) ->
        typeId

    setFormat: (format) ->
        format

    setUsername: (username) ->
        username

    submit: ->
        console.log 'submit', arguments

class PoiStore extends Store
    constructor: (flux) ->
        super()

        actions = flux.getActions 'poi'
        @register actions.setType, @handleType
        @register actions.setFormat, @handleFormat
        @register actions.setUsername, @handleUsername
        @state =
            format: 'gpx'

    handleType: (typeId) ->
        @setState
            "type-#{typeId}": not @state["type-#{typeId}"]

    handleFormat: (format) ->
        @setState
            format: format

    handleUsername: (username) ->
        @setState
            username: username

    @serialize: (state) ->
        JSON.stringify state

    @deserialize: (json) ->
        JSON.parse json

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
}), document.body

$ = window.$;#$ = require 'jquery'

saveAs = require 'FileSaver'
JSZip = require 'jszip'

setTimeout ->
    flux.getActions('poi').setType 'traditional'
, 2000

$('.submit.button').click ->
    $('.form').addClass 'loading'
    files = $.makeArray $('.form input[type=checkbox').map (i, input) ->
        url: "https://gc.funkenburg.net/api/poi.csv?type=#{input.value}"
        name: "#{input.id.substr(5)}.csv"
    zip = new JSZip()
    zipFolder = zip.folder 'poi'
    h = (name, data) ->
        if data?
            zipFolder.file name, data
        if files.length is 0
            zipBlob = zip.generate type: 'blob'
            saveAs zipBlob, 'poi.zip'
            $('.form').removeClass 'loading'
        else
            next = files.shift()
            $.get next.url
                .done (data) -> h next.name, data
                .fail ->
                    $('.form').removeClass('loading').addClass('error')
    h()


setTimeout ->
    console.log flux.serialize()
, 5000
