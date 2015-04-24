#!/usr/bin/env coffee
Promise = require 'bluebird'

main = Promise.coroutine ->
    GeocacheService = require './geocache-service'
    AccessService = require './access-service'

    geocacheService = new GeocacheService

    accessService = new AccessService 'postgres://127.0.0.1/gc'
    token = yield accessService.init()
    console.log "Token: #{token}"

    app = require('./rest')
        geocache: geocacheService
        access: accessService

    console.log 'Listening on port 8081'
    app.listen 8081

main()
