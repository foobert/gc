async = require '../rest-async'
JSONStream = require 'JSONStream'
Promise = require 'bluebird'

etag = (gc) ->
    return null if not gc?
    time = gc.DateLastUpdate
    match = time?.match /^\/Date\((\d+)-(\d{2})(\d{2})\)\/$/
    return null if not match?
    seconds_epoch = parseInt(match[1]) / 1000
    timezone_hours = parseInt(match[2]) * 60 * 60
    timezone_minutes = parseInt(match[3]) * 60
    new Date((seconds_epoch - timezone_hours - timezone_minutes) * 1000).toISOString()

module.exports = (app, geocache) ->
    app.get '/geocaches', async (req, res, next) ->
        res.set 'Content-Type', 'application/json; charset=utf-8'
        geocacheStream = yield geocache.getStream req.query, true
        geocacheStream
            .pipe JSONStream.stringify('[', ',', ']')
            .pipe res

    app.get '/geocaches?/:gc', async (req, res, next) ->
        gc = yield geocache.get req.params.gc
        if not gc?
            res.status 404
            res.send '404 - Geocache not found\n'
        else
            res.set 'ETag', etag gc
            res.set 'Content-Type', 'application/json; charset=utf-8'
            res.json gc

    app.head '/geocache/:gc', async (req, res, next) ->
        gc = yield geocacheservice.get req.params.gc
        if not gc?
            res.status 404
            res.send '404 - Geocache not found\n'
        else
            res.set 'ETag', etag gc
            res.end

    app.post '/geocache', async (req, res, next) ->
        yield geocache.upsert req.body
        res.status 201
        res.send ''

    app.get '/geocache/:gc/seen', async (req, res, next) ->
        gc = yield geocache.get req.params.gc
        res.status 200
        res.send gc.meta.updated

    app.put '/geocache/:gc/seen', async (req, res, next) ->
        now = Date.parse req.body
        yield geocache.touch req.params.gc
        res.status 200
        res.send ''

    app.delete '/geocaches', async (req, res, next) ->
        yield geocache.deleteAll()
        res.status 204
        res.send ''

    app.delete '/geocaches/:gc', async (req, res, next) ->
        yield geocache.delete req.params.gc
        res.status 204
        res.send ''

    app.get '/gcs', async (req, res, next) ->
        res.set 'Content-Type', 'application/json; charset=utf-8'
        gcStream = yield geocache.getStream req.query, false
        gcStream
            .pipe JSONStream.stringify('[', ',', ']')
            .pipe res
