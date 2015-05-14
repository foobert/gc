#!/usr/bin/env coffee
Promise = require 'bluebird'
Promise.longStackTraces()


main = Promise.coroutine ->
    GeocacheService = require './geocache-service'
    AccessService = require './access-service'

    connectionString = "postgres://postgres@#{process.env.DB_PORT_5432_TCP_ADDR}/gc"
    console.log connectionString
    db = require('./db') connectionString
    geocacheService = new GeocacheService db
    accessService = new AccessService db
    token = yield accessService.init()
    console.log "Token: #{token}"

    app = require('./rest')
        geocache: geocacheService
        access: accessService

    console.log 'Listening on port 8081'
    app.listen 8081

main()
