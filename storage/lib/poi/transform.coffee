stream = require 'stream'

class Mapper extends stream.Transform
    constructor: (@mapper) ->
        super objectMode: true

    _transform: (obj, encoding, cb) ->
        cb null, @mapper obj

    _flush: (cb) ->
        cb()

module.exports = (mapper) ->
    new Mapper mapper
