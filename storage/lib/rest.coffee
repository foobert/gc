express = require 'express'
bodyParser = require 'body-parser'
Promise = require 'bluebird'
JSONStream = require 'JSONStream'

module.exports = (services) ->
    accessService = services.access
    geocacheService = services.geocache

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

        if yield accessService.check req.get 'X-Token'
            return next()

        res
            .status 403
            .send 'Valid API token required'

    app.get '/', (req, res, next) ->
        res.status 200
        res.send 'Okay'

    app.get '/geocaches', async (req, res, next) ->
        res.set 'Content-Type', 'application/json'
        geocacheStream = yield geocacheService.getStream req.query, true
        geocacheStream
            .pipe JSONStream.stringify('[', ',', ']')
            .pipe res

    app.get '/geocache/:gc', async (req, res, next) ->
        geocache = yield geocacheService.get req.params.gc
        if not geocache?
            res.status 404
            res.send '404 - Geocache not found\n'
        else
            res.header 'ETag', etag geocache
            res.json geocache

    app.head '/geocache/:gc', async (req, res, next) ->
        geocache = yield geocacheservice.get req.params.gc
        if not geocache?
            res.status 404
            res.send '404 - Geocache not found\n'
        else
            res.header 'ETag', etag geocache
            res.end

    app.put '/geocaches', async (req, res, next) ->
        models = if typeof req.body is 'array'
            req.body
        else
            [req.body]

        yield geocacheService.upsertBulk models
        res.status 201
        res.send ''

    app.post '/geocache', async (req, res, next) ->
        yield geocacheService.upsert req.body
        res.status 201
        res.send ''

    app.put '/geocache/:gc/seen', async (req, res, next) ->
        now = Date.parse req.body
        yield geocacheService.touch req.params.gc
        res.status 200
        res.send ''

    app.delete '/geocaches', async (req, res, next) ->
        yield geocacheService.deleteAll()
        res.status 204
        res.send ''

    app.get '/gcs', async (req, res, next) ->
        res.set 'Content-Type', 'application/json'
        geocacheStream = yield geocacheService.getStream req.query, false
        geocacheStream
            .pipe JSONStream.stringify('[', ',', ']')
            .pipe res

    app.use (err, req, res, next) ->
        console.error err.stack
        res.status 500
        res.send ':-('

    etag = (geocache) ->
        return null if not geocache?
        time = geocache.DateLastUpdate
        match = time.match /^\/Date\((\d+)-(\d{2})(\d{2})\)\/$/
        return null if not match?
        seconds_epoch = parseInt(match[1]) / 1000
        timezone_hours = parseInt(match[2]) * 60 * 60
        timezone_minutes = parseInt(match[3]) * 60
        new Date((seconds_epoch - timezone_hours - timezone_minutes) * 1000).toISOString()

    return app
