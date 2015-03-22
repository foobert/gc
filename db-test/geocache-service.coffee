pg = require 'pg'
squel = require 'squel'
JSONStream = require 'JSONStream'
Promise = require 'bluebird'
Promise.promisifyAll pg

class GeocacheService
    _queryGeocaches: (query, withData, cb) ->
        pg.connect 'postgres://localhost/gc', (err, client, done) ->
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

            if query.excludeDisabled is 1
                sql = sql
                    .where "data @> '{\"Archived\": false, \"Available\": true}'"

            console.log sql.toString()

            query = client.query sql.toString()

            query.on 'row', (row) -> cb null, row
            query.on 'error', (err) -> cb err
            query.on 'end', (result) -> cb null, null

    get: (query, stream, withData) ->
        out = JSONStream.stringify('[', ',', ']')
        out.pipe stream

        @_queryGeocaches query, withData, (err, row) ->
            #return res.send 500 if err?
            return out.end() unless row?

            if withData
                row.data.meta =
                    updated: row.updated
                out.write row.data
            else
                out.write row.id.trim().toUpperCase()

    _upsert: (client, data) ->
        data.meta = null
        id = data.Code.toLowerCase

        try
            yield client.queryAsync 'BEGIN'

            result = yield client.query squel.select
                .field 'id'
                .from 'geocaches'
                .where 'id = ?', id
                .toString()

            if result.rows is 0
                yield client.insert squel.insert
                    .into 'geocaches'
                    .set 'id', id
                    .set 'updated', 'CURRENT_TIMESTAMP'
                    .set 'data', JSON.stringify data
            else
                client.update squel.update
                    .table 'geocaches'
                    .set 'updated', 'CURRENT_TIMESTAMP'
                    .set 'data', JSON.stringify data
                    .where 'id = ?', id
        catch err
            yield client.queryAsync 'ROLLBACK'
    upsert: Promise.coroutine (data) ->
        [client, done] = yield pg.connectAsync 'postgres://localhost/gc'
        try
            yield _upsert client, data
        finally
            done()

    upsertBulk: Promise.coroutine (datas) ->
        [client, done] = yield pg.connectAsync 'postgres://localhost/gc'
        try
            for data in datas
                yield _upsert client, data
        finally
            done()

module.exports = GeocacheService
