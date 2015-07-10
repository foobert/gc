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

    require('./geocache/rest') app, geocache
    require('./poi/rest') app, geocache

    app.use (err, req, res, next) ->
        console.error err.stack
        res.status 500
        res.send ':-('

    return app
