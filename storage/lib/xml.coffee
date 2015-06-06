stream = require 'stream'
xml2js = require 'xml2js'

class XmlStream extends stream.Transform
    constructor: (@pre, @post, @mapper) ->
        super objectMode: true
        @builder = new xml2js.Builder
            headless: true
            renderOpts: pretty: false
        @push @pre

    _transform: (obj, encoding, cb) ->
        cb null, @builder.buildObject @mapper obj

    _flush: (cb) ->
        @push @post
        cb()

module.exports = 
    transform: (pre, post, mapper) ->
        new XmlStream pre, post, mapper
