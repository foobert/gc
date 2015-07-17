bodyParser = require 'body-parser'
compression = require 'compression'
express = require 'express'
Promise = require 'bluebird'

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

    require('./geocache/rest') app, geocache
    require('./poi/rest') app, geocache
    require('./feed/rest') app, geocache
    require('./geolog/rest') app, geolog

    app.use (err, req, res, next) ->
        console.error err.stack
        res.status 500
        res.send ':-('

    return app
