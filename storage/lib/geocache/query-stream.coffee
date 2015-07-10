stream = require 'stream'

class QueryStream extends stream.Readable
    constructor: (query, map, done) ->
        super objectMode: true

        query.on 'row', (row) =>
            @push map(row)
        query.on 'end', (result) =>
            @push null
            done()
        query.on 'error', (err) =>
            @push null
            done(err)

    _read: ->

module.exports = QueryStream
