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

    app.use (err, req, res, next) ->
        console.error err
        res
            .status 500
            .send ':-('

    app.use Promise.coroutine (req, res, next) ->
        isValid = yield accessService.validate req.path, req.method, req.get 'X-Token'
        if isValid
            next()
        else
            res
                .status 403
                .send 'Valid API token required'

    app.get '/geocaches', Promise.coroutine (req, res, next) ->
        res.set 'Content-Type', 'application/json'
        geocacheStream = yield geocacheService.getStream req.query, true
        geocacheStream
            .pipe JSONStream.stringify('[', ',', ']')
            .pipe res

    app.get '/geocache/:gc', Promise.coroutine (req, res, next) ->
        geocache = yield geocacheService.getSingle req.params.gc
        res.json geocache

    app.put '/geocaches', Promise.coroutine (req, res, next) ->
        yield geocacheService.upsertBulk req.body
        res.status 201
        res.send ''

    app.delete '/geocaches', Promise.coroutine (req, res, next) ->
        yield geocacheService.deleteAll()
        res.status 202
        res.send ''

    app.get '/gcs', Promise.coroutine (req, res, next) ->
        res.set 'Content-Type', 'application/json'
        geocacheStream = yield geocacheService.getStream req.query, false
        geocacheStream
            .pipe JSONStream.stringify('[', ',', ']')
            .pipe res

    return app
