express = require 'express'
pg = require 'pg'
squel = require 'squel'
JSONStream = require 'JSONStream'
Promise = require 'bluebird'
Promise.promisifyAll pg

GeocacheService = require './geocache-service'

geocacheService = new GeocacheService

app = express()

app.get '/geocaches', Promise.coroutine (req, res, next) ->
    try
        result = yield geocacheService.get2 req.query, true
        res.set 'Content-Type', 'application/json'
        res.send JSON.stringify result
    catch err
        res.send 500

app.put '/geocaches', Promise.coroutine (req, res, next) ->
    yield geocacheService.upsertBulk req.body
    res.send 201

app.get '/gcs', (req, res, next) ->
    geocacheService.get req.query, res, false

app.listen 8081
