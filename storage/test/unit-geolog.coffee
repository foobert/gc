fs = require 'fs'
Promise = require 'bluebird'
{expect} = require 'chai'

describe 'geolog', ->
    @timeout 5000

    db = null
    geologs = null

    GL00001 = null
    GL00002 = null

    before Promise.coroutine ->
        db = require('../lib/db')
            host: process.env.DB_PORT_5432_TCP_ADDR ? 'localhost'
            user: process.env.DB_USER ? 'postgres'
            password: process.env.DB_PASSWORD
            database: process.env.DB ? 'gc'
        yield db.up()
        geologs = require('../lib/geolog') db

        GL00001 = JSON.parse fs.readFileSync "#{__dirname}/data/GL00001", 'utf8'
        GL00002 = JSON.parse fs.readFileSync "#{__dirname}/data/GL00002", 'utf8'

    beforeEach Promise.coroutine ->
        [client, done] = yield db.connect()
        yield client.queryAsync 'DELETE FROM logs'
        done()

    get = Promise.coroutine (id) ->
        [client, done] = yield db.connect()
        try
            result = yield client.queryAsync 'SELECT data FROM logs WHERE lower(id) = lower($1)', [id]
            return result.rows[0]?.data
        finally
            done()

    describe 'upsert', ->
        it 'should insert a new geolog', Promise.coroutine ->
            yield geologs.upsert GL00001
            gl = yield get 'GL00001'
            expect(gl).to.deep.equal GL00001

        it 'should update an existing geolog', Promise.coroutine ->
            copy = JSON.parse JSON.stringify GL00001
            copy.LogText = 'TYFTC'
            yield geologs.upsert GL00001
            yield geologs.upsert copy
            gl = yield get 'GL00001'
            expect(gl.LogText).to.equal 'TYFTC'

    describe 'latest', ->
        it 'should return the latest log for a given username', Promise.coroutine ->
            yield geologs.upsert GL00001
            yield geologs.upsert GL00002
            latest = yield geologs.latest 'Foobar'
            expect(latest).to.equal 'GL00001'

        it 'should return null if no geologs exist', Promise.coroutine ->
            latest = yield geologs.latest 'nobody'
            expect(latest).to.not.exist

    describe 'deleteAll', ->
        it 'should delete all logs', Promise.coroutine ->
            yield geologs.upsert GL00001
            yield geologs.upsert GL00002
            yield geologs.deleteAll()
            [client, done] = yield db.connect()
            try
                result = yield client.queryAsync 'SELECT count(*) FROM logs'
                expect(result.rows[0].count).to.equal '0'
            finally
                done()

