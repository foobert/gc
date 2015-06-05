express = require 'express'
bodyParser = require 'body-parser'
Promise = require 'bluebird'
JSONStream = require 'JSONStream'

module.exports = (services) ->
    {access, geocache} = services

    app = express()

    app.set 'x-powered-by', false
    app.set 'etag', false
    app.use bodyParser.json()

    async = (f) ->
        Promise.coroutine (req, res, next) ->
            try
                yield from f req, res, next
            catch err
                next err

    app.use Promise.coroutine (req, res, next) ->
        if req.method in ['GET', 'HEAD', 'OPTIONS']
            return next()

        if yield access.check req.get 'X-Token'
            return next()

        res
            .status 403
            .send 'Valid API token required'

    app.get '/', (req, res, next) ->
        res.status 200
        res.send 'Okay'

    app.get '/geocaches', async (req, res, next) ->
        res.set 'Content-Type', 'application/json'
        geocacheStream = yield geocache.getStream req.query, true
        geocacheStream
            .pipe JSONStream.stringify('[', ',', ']')
            .pipe res

    app.get '/geocache/:gc', async (req, res, next) ->
        gc = yield geocache.get req.params.gc
        if not gc?
            res.status 404
            res.send '404 - Geocache not found\n'
        else
            res.header 'ETag', etag gc
            res.json gc

    app.head '/geocache/:gc', async (req, res, next) ->
        gc = yield geocacheservice.get req.params.gc
        if not gc?
            res.status 404
            res.send '404 - Geocache not found\n'
        else
            res.header 'ETag', etag gc
            res.end

    app.put '/geocaches', async (req, res, next) ->
        models = if typeof req.body is 'array'
            req.body
        else
            [req.body]

        yield geocache.upsertBulk models
        res.status 201
        res.send ''

    app.post '/geocache', async (req, res, next) ->
        yield geocache.upsert req.body
        res.status 201
        res.send ''

    app.put '/geocache/:gc/seen', async (req, res, next) ->
        now = Date.parse req.body
        yield geocache.touch req.params.gc
        res.status 200
        res.send ''

    app.delete '/geocaches', async (req, res, next) ->
        yield geocache.deleteAll()
        res.status 204
        res.send ''

    app.get '/gcs', async (req, res, next) ->
        res.set 'Content-Type', 'application/json'
        gcStream = yield geocache.getStream req.query, false
        gcStream
            .pipe JSONStream.stringify('[', ',', ']')
            .pipe res

    app.use (err, req, res, next) ->
        console.error err.stack
        res.status 500
        res.send ':-('

    etag = (gc) ->
        return null if not gc?
        time = gc.DateLastUpdate
        match = time.match /^\/Date\((\d+)-(\d{2})(\d{2})\)\/$/
        return null if not match?
        seconds_epoch = parseInt(match[1]) / 1000
        timezone_hours = parseInt(match[2]) * 60 * 60
        timezone_minutes = parseInt(match[3]) * 60
        new Date((seconds_epoch - timezone_hours - timezone_minutes) * 1000).toISOString()

    return app
