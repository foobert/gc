pg = require 'pg'
squel = require('squel').useFlavour 'postgres'
Promise = require 'bluebird'
Promise.promisifyAll pg

process.on 'SIGINT', ->
    pg.end()
    process.exit()

module.exports = (options) ->
    migrate = require('./migrate') options

    select: squel.select
    insert: squel.insert
    update: squel.update
    delete: squel.delete
    connect: pg.connectAsync.bind pg, options
    up: Promise.coroutine ->
        yield migrate.up [
            'CREATE TABLE geocaches (id char(8) PRIMARY KEY, updated timestamp with time zone NOT NULL, data jsonb)'
            'CREATE TABLE tokens (id uuid UNIQUE)'
        ]
        yield migrate.up [
            'CREATE TABLE logs (id char(8) PRIMARY KEY, updated timestamp with time zone NOT NULL, data jsonb)'
            """
            CREATE VIEW logsRel AS
                SELECT id
                     , updated
                     , data->>\'CacheCode\' as cachecode
                     , data->\'Finder\'->>\'UserName\' as username
                     , data->\'LogType\'->>\'WptLogTypeId\' as logtype
                     , (date \'epoch\' + (substring(data->>\'UTCCreateDate\' from 7 for 10)::numeric * interval \'1 second\')) as createdate
                FROM logs
            """
        ]
        yield migrate.up [
            """
            CREATE MATERIALIZED VIEW founds AS
                SELECT
                    c.id,
                    array(SELECT DISTINCT l.username FROM logsRel l WHERE lower(l.cachecode) = c.id AND l.logtype = '2') AS usernames
                FROM geocaches c
            """
        ]
