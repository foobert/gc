require '../css/index.css'

require 'jquery'

saveAs = require 'FileSaver'
JSZip = require 'jszip'

$ ->
    $('.ui.checkbox').checkbox()
    $('.ui.radio.checkbox').checkbox()

    $('.submit.button').click ->
        $('.form').addClass 'loading'
        files = [
            url: 'https://gc.funkenburg.net/api/poi.csv?type=3'
            name: 'multi.csv'
        ,
            url: 'http://gc.funkenburg.net/api/poi.csv?type=2'
            name: 'tradi.csv'
        ]
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
