#!/usr/bin/env coffee
Promise = require 'bluebird'
Promise.longStackTraces()

do Promise.coroutine ->
    GeocacheService = require './lib/geocache'
    AccessService = require './lib/access'

    db = require('./lib/db')
        host: process.env.DB_PORT_5432_TCP_ADDR ? 'localhost'
        user: process.env.DB_USER ? process.env.USER
        password: process.env.DB_PASSWORD
        database: process.env.DB ? 'gc'
    yield db.up()

    geocacheService = new GeocacheService db
    accessService = new AccessService db
    token = yield accessService.init()
    console.log "Token: #{token}"

    app = require('./lib/rest')
        geocache: geocacheService
        access: accessService

    console.log 'Listening on port 8081'
    app.listen 8081
