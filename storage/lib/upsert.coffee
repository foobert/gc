Promise = require 'bluebird'

upsert = Promise.coroutine (db, client, table, data) ->
    console.log data
    id = data.Code?.toLowerCase()
    updated = data.meta?.updated
    delete data.meta

    throw new Error "Missing data attribute 'Code'" if not id?

    try
        yield client.queryAsync 'BEGIN'

        sql = db.select()
            .field 'id'
            .from table
            .where 'id = ?', id
            .toString()
        result = yield client.queryAsync sql
        sql = if result.rowCount is 0
            db.insert numberedParameters: true
                .into table
                .set 'id', id
                .set 'updated', updated or 'now', dontQuote: not updated?
                .set 'data', JSON.stringify data
                .toParam()
        else
            db.update numberedParameters: true
                .table table
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

module.exports = Promise.coroutine (db, table, data) ->
    [client, done] = yield db.connect()
    try
        yield upsert db, client, table, data
    finally
        done()
