pg = require 'pg'
squel = require 'squel'
Promise = require 'bluebird'
Promise.promisifyAll pg

process.on 'SIGINT', -> pg.end()

module.exports = (options) ->
    migrate = require('./migrate') options

    select: squel.select
    insert: squel.insert
    update: squel.update
    delete: squel.delete
    connect: pg.connectAsync.bind pg, options
    up: Promise.coroutine ->
        yield migrate.up [
            'CREATE TABLE geocaches (id char(8) PRIMARY KEY, updated timestamp with time zone NOT NULL, data jsonb)',
            'CREATE TABLE tokens (id uuid UNIQUE)'
        ]
