pg = require 'pg'
squel = require 'squel'
highland = require 'highland'
Promise = require 'bluebird'
Promise.promisifyAll pg

class AccessService
    validate: Promise.coroutine (route, method, token) ->
        return true if method in ['GET', 'OPTIONS', 'HEAD']

        yield @checkToken token

    checkToken: Promise.coroutine (token) ->
        return false if not token?

        [client, done] = yield pg.connectAsync 'postgres://localhost/gc'
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

module.exports = AccessService
