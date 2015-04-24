uuid = require 'uuid'
pg = require 'pg'
squel = require 'squel'
Promise = require 'bluebird'
Promise.promisifyAll pg

class AccessService
    constructor: (@connectionString) ->

    init: Promise.coroutine ->
        token = yield @getToken()
        if not token?
            token = yield @addToken()
        return token
        #console.log "Token: #{token}"

    check: Promise.coroutine (token) ->
        return false if not token?

        [client, done] = yield pg.connectAsync @connectionString
        try
            sql = squel.select()
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
        [client, done] = yield pg.connectAsync @connectionString
        try
            sql = squel.insert()
                .into 'tokens'
                .set 'id', token
                .toString()
            result = yield client.queryAsync sql
            return token
        finally
            done()

    getToken: Promise.coroutine ->
        [client, done] = yield pg.connectAsync @connectionString
        try
            sql = squel.select()
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

