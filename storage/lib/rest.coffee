bodyParser = require 'body-parser'
compression = require 'compression'
express = require 'express'
JSONStream = require 'JSONStream'
Promise = require 'bluebird'

async = require './rest-async'

module.exports = (services) ->
    {access, geocache, geolog} = services

    app = express()

    app.set 'x-powered-by', false
    app.set 'etag', false
    app.use compression()
    app.use bodyParser.json()

    app.use Promise.coroutine (req, res, next) ->
        if req.method in ['GET', 'HEAD', 'OPTIONS']
            return next()

        if yield access.check req.get 'X-Token'
            return next()

        res
            .status 403
            .send 'Valid API token required'

    app.use (req, res, next) ->
        res.set 'Access-Control-Allow-Origin', '*'
        res.set 'Access-Control-Allow-Methods', 'GET, OPTIONS, HEAD'
        next()

    app.get '/', (req, res, next) ->
        res.status 200
        res.send 'Okay'

    app.get '/geocaches', async (req, res, next) ->
        res.set 'Content-Type', 'application/json'
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
        res.set 'Content-Type', 'application/json'
        gcStream = yield geocache.getStream req.query, false
        gcStream
            .pipe JSONStream.stringify('[', ',', ']')
            .pipe res

    app.post '/log', async (req, res, next) ->
        yield geolog.upsert req.body
        res.status 201
        res.send ''

    app.get '/logs/latest', async (req, res, next) ->
        id = yield geolog.latest req.query.username
        if id?
            res.status(200).send id
        else
            res.status(404).send 'No logs'

    app.post '/sillyRefresh', async (req, res, next) ->
        yield geolog.refresh()
        res.status 200
        res.send 'Refreshed'

    require('./poi/rest') app, geocache

    app.use (err, req, res, next) ->
        console.error err.stack
        res.status 500
        res.send ':-('

    etag = (gc) ->
        return null if not gc?
        time = gc.DateLastUpdate
        match = time?.match /^\/Date\((\d+)-(\d{2})(\d{2})\)\/$/
        return null if not match?
        seconds_epoch = parseInt(match[1]) / 1000
        timezone_hours = parseInt(match[2]) * 60 * 60
        timezone_minutes = parseInt(match[3]) * 60
        new Date((seconds_epoch - timezone_hours - timezone_minutes) * 1000).toISOString()

    return app
