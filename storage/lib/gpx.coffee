stream = require 'stream'
poi = require './poi'

module.exports = class GpxStream extends stream.Transform
    constructor: (options) ->
        options ?= {}
        options.objectMode = true
        super options

    _transform: (gc, encoding, cb) ->
        cb null,
            wpt:
                $:
                    lat: gc.Latitude
                    lon: gc.Longitude
                name: poi.title gc
                cmt: poi.description gc
                type: 'Geocache'

    _flush: (cb) ->
        cb()
