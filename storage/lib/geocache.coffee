debug = require('debug') 'gc:geocaches'
refreshView = require './refresh-view'
upsert = require './upsert'
Promise = require 'bluebird'
QueryStream = require './query-stream'

module.exports = (db) ->
    _refreshView = refreshView db, 'geocachesRel', 5000, debug

    _mapRow = (row, options = {}) ->
        return null unless row?
        options.withData ?= true
        if options.withData
            Code: row.id
            Name: row.name
            Latitude: parseFloat row.latitude
            Longitude: parseFloat row.longitude
            Terrain: parseFloat row.terrain
            Difficulty: parseFloat row.difficulty
            Archived: row.archived
            Available: row.available
            CacheType: GeocacheTypeId: parseInt row.geocachetypeid
            ContainerType: ContainerTypeName: row.containertypename
            EncodedHints: row.encodedhints
            meta: updated: row.updated
        else
            row.id

    _queryGeocaches = Promise.coroutine (query, withData) ->
        debug "query #{JSON.stringify query}, #{withData}"
        [client, done] = yield db.connect()
        sql = db.select tableAliasQuoteCharacter: '"'
            .from 'geocachesRel'

        sql = sql
            .field 'upper(trim(id))', 'id'
            .field 'updated'

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
            [lat0, lng0, lat1, lng1] = query.bounds.map (x) -> parseFloat x
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

        rows = client.query sql.toString()
        map = (row) => _mapRow row, withData: withData
        geocacheStream = new QueryStream rows, map, done

        return geocacheStream

    getStream: (query, withData) ->
        _queryGeocaches query, withData

    get: Promise.coroutine (id) ->
        debug "get #{id}"
        [client, done] = yield db.connect()
        try
            sql = db.select()
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
        debug "touch #{id}"
        [client, done] = yield db.connect()
        try
            sql = db.update numberedParameters: true
                .table 'geocaches'
                .set 'updated', date?.toISOString() or 'now', dontQuote: not date?
                .where 'id = ?', id.trim().toLowerCase()
                .toParam()
            result = yield client.queryAsync sql
            _refreshView()
        finally
            done()

    upsert: Promise.coroutine (data) ->
        debug "upsert #{data.Code?.toLowerCase()}"
        yield upsert db, 'geocaches', data
        _refreshView()

    delete: Promise.coroutine (id) ->
        debug "delete #{id}"
        [client, done] = yield db.connect()
        try
            sql = db.delete()
                    .from 'geocaches'
                    .where 'id = ?', id.trim().toLowerCase()
                    .toString()
            yield client.queryAsync sql
            _refreshView()
        finally
            done()

    deleteAll: Promise.coroutine ->
        debug "delete all"
        [client, done] = yield db.connect()
        try
            sql = db.delete()
                .from 'geocaches'
                .toString()
            yield client.queryAsync sql
            _refreshView()
        finally
            done()
