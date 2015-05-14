express = require 'express'
bodyParser = require 'body-parser'
Promise = require 'bluebird'
JSONStream = require 'JSONStream'

module.exports = (services) ->
    accessService = services.access
    geocacheService = services.geocache

    app = express()

    app.set 'x-powered-by', false
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
            res.json geocache

    app.put '/geocaches', async (req, res, next) ->
        models = if typeof req.body is 'array'
            req.body
        else
            [req.body]

        yield geocacheService.upsertBulk models
        res.status 201
        res.send ''

    app.delete '/geocaches', async (req, res, next) ->
        yield geocacheService.deleteAll()
        res.status 202
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

    return app
