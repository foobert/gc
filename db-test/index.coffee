#!/usr/bin/env coffee
Promise = require 'bluebird'

main = Promise.coroutine ->
    GeocacheService = require './geocache-service'
    AccessService = require './access-service'

    connectionString = 'postgres://127.0.0.1/gc'
    geocacheService = new GeocacheService connectionString
    accessService = new AccessService connectionString
    token = yield accessService.init()
    console.log "Token: #{token}"

    app = require('./rest')
        geocache: geocacheService
        access: accessService

    console.log 'Listening on port 8081'
    app.listen 8081

main()
