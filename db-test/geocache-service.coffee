pg = require 'pg'
squel = require 'squel'
highland = require 'highland'
Promise = require 'bluebird'
Promise.promisifyAll pg
stream = require 'stream'

class QueryStream extends stream.Readable
    constructor: (query, map, done) ->
        super objectMode: true

        query.on 'row', (row) =>
            @push map(row)
        query.on 'end', (result) =>
            @push null
            done()
        query.on 'error', (err) =>
            @push null
            done(err)

    _read: ->

class GeocacheService
    constructor: (@connectionString) ->

    _queryGeocaches: Promise.coroutine (query, withData) ->
        [client, done] = yield pg.connectAsync @connectionString
        sql = squel.select()
            .from 'geocaches'
            .field 'id'
            .field 'updated'

        if withData
            sql = sql
                .field 'data'

        if query.stale isnt '1'
            sql = sql
                .where "age(updated) < interval '3 days'"

        if query.maxAge?
            sql = sql
                .where "age(date 'epoch' + (substring(data->>'UTCPlaceDate' from 7 for 10)::numeric - substring(data->>'UTCPlaceDate' from 21 for 2)::numeric * 3600) * interval '1 second') < interval ?", "#{query.maxAge} days"

        if query.bounds?
            [lat0, lng0, lat1, lng1] = query.bounds
            sql = sql
                .where "(data->>'Latitude')::numeric >= ?", lat0
                .where "(data->>'Latitude')::numeric <= ?", lat1
                .where "(data->>'Longitude')::numeric >= ?", lng0
                .where "(data->>'Longitude')::numeric <= ?", lng1

        if query.typeIds?
            typeIds = query.typeIds
                .map (typeId) -> "'#{parseInt(typeId)}'"
                .join ','
            sql = sql
                .where "data->'CacheType'->>'GeocacheTypeId' = ANY(ARRAY[#{typeIds}])"

        # query.attributeIds is currently not supported

        if query.excludeDisabled is '1'
            sql = sql
                .where "data @> '{\"Archived\": false, \"Available\": true}'"

        console.log sql.toString()

        query = client.query sql.toString()
        map = (row) => @_mapRow row, withData
        geocacheStream = new QueryStream query, map, done

        return geocacheStream

    getStream: (query, withData) ->
        @_queryGeocaches query, withData

    _mapRow: (row, withData = true) ->
        if withData
            result = row.data
            result.meta =
                updated: row.updated
            return result
        else
            return row.id.trim().toUpperCase()

    get: Promise.coroutine (id) ->
        [client, done] = yield pg.connectAsync @connectionString
        try
            row = yield client.query squel.select()
                .from 'geocaches'
                .field 'updated'
                .field 'data'
                .where 'id = ?', id.trim().toLowerCase()
            return @_mapRow row, true
        finally
            done()

    _upsert: Promise.coroutine (client, data) ->
        id = data.Code?.toLowerCase()
        updated = data.meta?.updated
        delete data.meta

        throw new Error "Missing geocache attribute 'Code'" if not id?

        try
            yield client.queryAsync 'BEGIN'

            sql = squel.select()
                .field 'id'
                .from 'geocaches'
                .where 'id = ?', id
                .toString()
            result = yield client.queryAsync sql
            sql = if result.rowCount is 0
                squel.insert()
                    .into 'geocaches'
                    .set 'id', id
                    .set 'updated', updated or 'CURRENT_TIMESTAMP', dontQuote: not updated?
                    .set 'data', JSON.stringify data
                    .toString()
            else
                squel.update()
                    .table 'geocaches'
                    .set 'updated', updated or 'CURRENT_TIMESTAMP', dontQuote: not updated?
                    .set 'data', JSON.stringify data
                    .where 'id = ?', id
                    .toString()
            console.log sql
            result = yield client.queryAsync sql
            throw new Error "Insert/update had no effect: #{sql}" if result.rowCount is 0
            yield client.queryAsync 'COMMIT'
        catch err
            yield client.queryAsync 'ROLLBACK'
            throw err

    upsert: Promise.coroutine (data) ->
        [client, done] = yield pg.connectAsync @connectionString
        try
            yield @_upsert client, data
        finally
            done()

    upsertBulk: Promise.coroutine (datas) ->
        [client, done] = yield pg.connectAsync @connectionString
        try
            for data in datas
                yield @_upsert client, data
        finally
            done()

    deleteAll: Promise.coroutine ->
        [client, done] = yield pg.connectAsync @connectionString
        try
            sql = squel.delete()
                .from 'geocaches'
                .toString()
            console.log sql
            yield client.queryAsync sql
        finally
            done()

module.exports = GeocacheService
