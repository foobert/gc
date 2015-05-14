uuid = require 'uuid'
Promise = require 'bluebird'

class AccessService
    constructor: (@db) ->

    init: Promise.coroutine ->
        return yield @getToken() or yield @addToken()

    check: Promise.coroutine (token) ->
        return false if not token?

        [client, done] = yield @db.connect()
        try
            sql = @db.select()
                .from 'tokens'
                .field 'id'
                .where 'id = ?', token
                .toString()

            result = yield client.queryAsync sql
            return result.rowCount is 1
        catch err
            return false
        finally
            done()

    addToken: Promise.coroutine ->
        token = uuid.v4()
        [client, done] = yield @db.connect()
        try
            sql = @db.insert()
                .into 'tokens'
                .set 'id', token
                .toString()
            result = yield client.queryAsync sql
            return token
        finally
            done()

    getToken: Promise.coroutine ->
        [client, done] = yield @db.connect()
        try
            sql = @db.select()
                .from 'tokens'
                .field 'id'
                .limit 1
                .toString()
            result = yield client.queryAsync sql
            if result.rowCount is 0
                return null
            else
                return result.rows[0].id
        finally
            done()

module.exports = AccessService

