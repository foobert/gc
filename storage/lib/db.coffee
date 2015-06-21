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
                     , data->>'CacheCode' as cachecode
                     , data->'Finder'->>'UserName' as username
                     , data->'LogType'->>'WptLogTypeId' as logtype
                     , (date 'epoch' + (substring(data->>'UTCCreateDate' from 7 for 10)::numeric * interval '1 second')) as createdate
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
        yield migrate.up [
            """
            CREATE MATERIALIZED VIEW geocachesRel AS
                SELECT
                    c.id,
                    c.updated as updated,
                    (c.data->>'Name') as Name,
                    (c.data->>'Latitude')::numeric as Latitude,
                    (c.data->>'Longitude')::numeric as Longitude,
                    (c.data->'CacheType'->>'GeocacheTypeId')::numeric as GeocacheTypeId,
                    c.data->'ContainerType'->>'ContainerTypeName' as ContainerTypeName,
                    (c.data->>'Difficulty')::numeric as Difficulty,
                    (c.data->>'Terrain')::numeric as Terrain,
                    c.data->>'EncodedHints' as EncodedHints,
                    (c.data->>'Archived')::bool as Archived,
                    (c.data->>'Available')::bool as Available,
                    (date 'epoch' + (substring(c.data->>'UTCPlaceDate' from 7 for 10)::numeric - substring(c.data->>'UTCPlaceDate' from 21 for 2)::numeric * 3600) * interval '1 second') as UTCPlaceDate
                FROM geocaches c
            """
        ]

