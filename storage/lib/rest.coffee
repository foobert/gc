bodyParser = require 'body-parser'
compression = require 'compression'
csv = require 'csv'
express = require 'express'
JSONStream = require 'JSONStream'
Promise = require 'bluebird'

poi = require './poi'
streamTransform = require './transform'
xml = require './xml'

module.exports = (services) ->
    {access, geocache} = services

    app = express()

    app.set 'x-powered-by', false
    app.set 'etag', false
    app.use compression()
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

    app.get '/poi.csv', async (req, res, next) ->
        res.set 'Content-Type', 'text/csv'
        gcStream = yield geocache.getStream req.query, true
        gcStream
            .pipe csv.transform (gc) ->
                [
                    gc.Longitude
                    gc.Latitude
                    poi.title gc
                    poi.description gc
                ]
            .pipe csv.stringify()
            .pipe res

    app.get '/poi.gpx', async (req, res, next) ->
        pre =  """
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"
version="1.1" creator="cachecache">
"""
        post = '</gpx>'

        res.set 'Content-Type', 'application/gpx+xml'
        gcStream = yield geocache.getStream req.query, true
        gcStream
            .pipe xml.transform pre, post, (gc) ->
                wpt:
                    $:
                        lat: gc.Latitude
                        lon: gc.Longitude
                    name: poi.title gc
                    cmt: poi.description gc
                    type: 'Geocache'
            .pipe res

    app.get '/poi.json', async (req, res, next) ->
        gcStream = yield geocache.getStream req.query, true
        gcStream
            .pipe streamTransform (gc) ->
                Code: gc.Code
                Name: gc.Name
                Available: gc.Available
                Archived: gc.Archived
                Difficulty: gc.Diffculty
                Terrain: gc.Terrain
                Latittude: gc.Latitude
                Longitude: gc.Longitude
                CacheType: GeocacheTypeId: gc.CacheType.GeocacheTypeId
                ContainerType: ContainerTypeName: gc.ContainerType.ContainerTypeName
                meta:
                    poi:
                        name: poi.title gc
                        description: poi.description gc
            .pipe JSONStream.stringify '[', ',', ']'
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
