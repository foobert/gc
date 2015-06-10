require '../css/index.css'

require 'jquery'

saveAs = require 'FileSaver'
JSZip = require 'jszip'

$ ->
    $('.ui.checkbox').checkbox()
    $('.ui.radio.checkbox').checkbox()

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
