#!/usr/bin/env coffee
Promise = require 'bluebird'
Promise.longStackTraces()

do Promise.coroutine ->
    db = require('./lib/db')
        host: process.env.DB_PORT_5432_TCP_ADDR ? 'localhost'
        user: process.env.DB_USER ? process.env.USER
        password: process.env.DB_PASSWORD
        database: process.env.DB ? 'gc'
    yield db.up()

    access = require('./lib/access') db
    token = yield access.init()
    console.log "Token: #{token}"

    app = require('./lib/rest')
        access: access
        geocache: require('./lib/geocache') db
        geolog: require('./lib/geolog') db

    console.log 'Listening on port 8081'
    app.listen 8081
