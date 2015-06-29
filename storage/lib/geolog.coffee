debug = require('debug') 'gc:geologs'
upsert = require './upsert'
Promise = require 'bluebird'

module.exports = (db) ->
    upsert: (data) ->
        debug "upsert #{data.Code?.toLowerCase()}"
        upsert db, 'logs', data

    latest: Promise.coroutine (username) ->
        debug "latest #{username}"
        [client, done] = yield db.connect()
        try
            sql = db.select()
                .from 'logsRel'
                .field 'id'
                .order 'visitdate', false
                .limit 1
            sql = sql.where 'lower(username) = ?', username.trim().toLowerCase() if username?
            sql = sql.toString()

            result = yield client.queryAsync sql
            if result.rowCount is 0
                return null
            else
                return result.rows[0].id.toUpperCase()
        finally
            done()
