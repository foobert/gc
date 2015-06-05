#!/usr/bin/env coffee
Promise = require 'bluebird'
Promise.longStackTraces()


main = Promise.coroutine ->
    GeocacheService = require './lib/geocache'
    AccessService = require './lib/access'

    connectionString = "postgres://postgres@#{process.env.DB_PORT_5432_TCP_ADDR}/gc"
    console.log connectionString
    db = require('./lib/db') connectionString
    geocacheService = new GeocacheService db
    accessService = new AccessService db
    token = yield accessService.init()
    console.log "Token: #{token}"

    app = require('./lib/rest')
        geocache: geocacheService
        access: accessService

    console.log 'Listening on port 8081'
    app.listen 8081

main()
