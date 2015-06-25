stream = require 'stream'
Promise = require 'bluebird'

class GeocacheService
    constructor: (@db) ->

    _queryGeocaches: Promise.coroutine (query, withData) ->
        [client, done] = yield @db.connect()
        sql = @db.select tableAliasQuoteCharacter: '"'
            .from 'geocachesRel'

        sql = sql
            .field 'upper(trim(id))', 'id'

        if withData
            sql = sql
                .field 'Name'
                .field 'Latitude'
                .field 'Longitude'
                .field 'Archived'
                .field 'Available'
                .field 'EncodedHints'
                .field 'Difficulty'
                .field 'Terrain'
                .field 'GeocacheTypeId'
                .field 'ContainerTypeName'

        if query.stale isnt '1'
            sql = sql
                .where "age(updated) < interval '3 days'"

        if query.maxAge?
            sql = sql
                .where "age(UTCPlaceDate) < interval ?", "#{query.maxAge} days"

        if query.bounds?
            [lat0, lng0, lat1, lng1] = query.bounds
            sql = sql
                .where "Latitude >= ?", lat0
                .where "Latitude <= ?", lat1
                .where "Longitude >= ?", lng0
                .where "Longitude <= ?", lng1

        if query.typeIds?
            sql = sql
                .where 'GeocacheTypeId IN ?', query.typeIds.map (x) -> parseInt x

        # query.attributeIds is currently not supported

        if query.excludeFinds?
            sql = sql
                .where 'not ? = any(found)', query.excludeFinds[0]

        if query.excludeDisabled is '1'
            sql = sql
                .where 'Archived = false'
                .where 'Available = true'

        console.log sql.toString()

        rows = client.query sql.toString()
        map = (row) => @_mapRow row, withData: withData
        geocacheStream = new QueryStream rows, map, done

        return geocacheStream

    getStream: (query, withData) ->
        @_queryGeocaches query, withData

    _mapRow: (row, options = {}) ->
        return null unless row?
        options.withData ?= true
        if options.withData
            Code: row.id
            Name: row.name
            Terrain: parseFloat row.terrain
            Difficulty: parseFloat row.difficulty
            Archived: row.archived
            Available: row.available
            CacheType: GeocacheTypeId: row.geocachetypeid
            ContainerType: ContainerTypeName: row.containertypename
            EncodedHints: row.encodedhints
        else
            row.id

    get: Promise.coroutine (id) ->
        [client, done] = yield @db.connect()
        try
            sql = @db.select()
                .from 'geocaches'
                .field 'updated'
                .field 'data'
                .where 'id = ?', id.trim().toLowerCase()
                .toString()
            result = yield client.queryAsync sql
            if result.rowCount is 0
                return null
            else
                row = result.rows[0]
                row.data.meta = updated: row.updated
                return row.data
        finally
            done()
    touch: Promise.coroutine (id, date) ->
        [client, done] = yield @db.connect()
        try
            sql = @db.update numberedParameters: true
                .table 'geocaches'
                .set 'updated', date or 'now', dontQuote: not date?
                .where 'id = ?', id
                .toParam()
            result = yield client.queryAsync sql
        finally
            done()

    _upsert: Promise.coroutine (client, data) ->
        console.log data
        id = data.Code?.toLowerCase()
        updated = data.meta?.updated
        delete data.meta

        throw new Error "Missing geocache attribute 'Code'" if not id?

        try
            yield client.queryAsync 'BEGIN'

            sql = @db.select()
                .field 'id'
                .from 'geocaches'
                .where 'id = ?', id
                .toString()
            result = yield client.queryAsync sql
            sql = if result.rowCount is 0
                @db.insert numberedParameters: true
                    .into 'geocaches'
                    .set 'id', id
                    .set 'updated', updated or 'now', dontQuote: not updated?
                    .set 'data', JSON.stringify data
                    .toParam()
            else
                @db.update numberedParameters: true
                    .table 'geocaches'
                    .set 'updated', updated or 'now', dontQuote: not updated?
                    .set 'data', JSON.stringify data
                    .where 'id = ?', id
                    .toParam()
            result = yield client.queryAsync sql
            throw new Error "Insert/update had no effect: #{sql}" if result.rowCount is 0
            yield client.queryAsync 'COMMIT'
        catch err
            yield client.queryAsync 'ROLLBACK'
            throw err

    upsert: Promise.coroutine (data) ->
        [client, done] = yield @db.connect()
        try
            yield @_upsert client, data
        finally
            done()

    upsertBulk: Promise.coroutine (datas) ->
        [client, done] = yield @db.connect()
        try
            for data in datas
                yield @_upsert client, data
        finally
            done()

    delete: Promise.coroutine (id) ->
        [client, done] = yield @db.connect()
        try
            sql = @db.delete()
                    .from 'geocaches'
                    .where 'id = ?', id.trim().toLowerCase()
                    .toString()
            console.log sql
            yield client.queryAsync sql
        finally
            done()

    deleteAll: Promise.coroutine ->
        [client, done] = yield @db.connect()
        try
            sql = @db.delete()
                .from 'geocaches'
                .toString()
            console.log sql
            yield client.queryAsync sql
        finally
            done()

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

module.exports = GeocacheService
