debug = require('debug') 'gc:migrate'
pg = require 'pg'
Promise = require 'bluebird'
Promise.promisifyAll pg

module.exports = ->
    expectedVersion = 0

    ensureDb = Promise.coroutine (db) ->
        [client, done] = yield db.connect 'postgres'
        try
            result = yield client.queryAsync 'SELECT 0 FROM pg_database WHERE datname = $1', [db.database]
            if result.rowCount isnt 1
                debug "creating database #{db.database}"
                # TODO possible sql injection?
                yield client.queryAsync "CREATE DATABASE #{db.database}"
        finally
            done()

    getCurrentVersion = Promise.coroutine (client) ->
        result = yield client.queryAsync 'SELECT 0 FROM pg_tables WHERE schemaname = \'public\' AND tablename = \'_schema\''
        if result.rowCount is 0
            yield client.queryAsync 'CREATE TABLE _schema (version integer)'

        result = yield client.queryAsync 'SELECT version FROM _schema'
        if result.rowCount isnt 0
            return result.rows[0].version
        else
            yield client.queryAsync 'INSERT INTO _schema VALUES(0)'
            return 0

    up: Promise.coroutine (db, statements) ->
        yield ensureDb db
        expectedVersion += 1
        [client, done] = yield db.connect()
        try
            currentVersion = yield getCurrentVersion client
            if currentVersion < expectedVersion
                debug "migrating from #{currentVersion} to #{expectedVersion}"
                yield client.queryAsync 'BEGIN'
                for statement in statements
                    debug statement
                    yield client.queryAsync statement
                yield client.queryAsync 'UPDATE _schema SET version = $1', [expectedVersion]
                yield client.queryAsync 'COMMIT'
        catch err
            yield client.queryAsync 'ROLLBACK' if client?
            throw err
        finally
            done err
