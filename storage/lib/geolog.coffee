Promise = require 'bluebird'
upsert = require './upsert'

module.exports = (db) ->
    upsert: upsert.bind this, db, 'logs'

    latest: Promise.coroutine (username) ->
        [client, done] = yield db.connect()
        try
            sql = db.select()
                .from 'logsRel'
                .field 'id'
                .order 'createdate', false
                .limit 1
            sql = sql.where 'lower(username) = ?', username.trim().toLowerCase() if username?
            sql = sql.toString()

            console.log sql
            result = yield client.queryAsync sql
            if result.rowCount is 0
                return null
            else
                return result.rows[0].id.toUpperCase()
        finally
            done()

