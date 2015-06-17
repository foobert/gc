{Actions} = require 'flummox'
{saveAs} = require 'node-safe-filesaver'
Promise = require 'bluebird'
JSZip = require 'jszip'
jquery = require 'jquery'

class PoiActions extends Actions
    setType: (typeId) ->
        typeId

    setFormat: (format) ->
        format

    setUsername: (username) ->
        username

    setFilename: (filename) ->
        filename

    submit: (types) ->
        new Promise (resolve, reject) =>
            files = types.map (type) ->
                url: "https://gc.funkenburg.net/api/poi.csv?type=#{type}"
                name: "#{type}.csv"
            zip = new JSZip()
            zipFolder = zip.folder 'poi'
            h = (name, data) =>
                if data?
                    zipFolder.file name, data
                if files.length is 0
                    zipBlob = zip.generate type: 'blob'
                    saveAs zipBlob, 'poi.zip'
                    resolve()
                else
                    next = files.shift()
                    @setFilename next.name
                    jquery.get next.url
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

module.exports = PoiActions
