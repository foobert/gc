stream = require 'stream'
xml2js = require 'xml2js'

module.exports = class XmlStream extends stream.Transform
    constructor: (options) ->
        options ?= {}
        options.objectMode = true
        super options
        @builder = new xml2js.Builder
            headless: true
            renderOpts: pretty: false
        @push """
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"
version="1.1" creator="cachecache">
"""

    _transform: (obj, encoding, cb) ->
        cb null, @builder.buildObject obj

    _flush: (cb) ->
        @push '</gpx>'
        cb()
