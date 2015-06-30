fs = require 'fs'
Promise = require 'bluebird'
{expect} = require 'chai'

describe.only 'geocache service', ->
    db = null
    geocaches = null

    before Promise.coroutine ->
        db = require('../lib/db')
            host: process.env.DB_PORT_5432_TCP_ADDR ? 'localhost'
            user: process.env.DB_USER ? 'postgres'
            password: process.env.DB_PASSWORD
            database: process.env.DB ? 'gc'
        yield db.up()
        geocaches = require('../lib/geocache') db

    describe 'get', ->
        GC1BAZ8 = null

        before ->
            GC1BAZ8 = JSON.parse fs.readFileSync "#{__dirname}/data/GC1BAZ8", 'utf8'

        beforeEach Promise.coroutine ->
            [client, done] = yield db.connect()
            yield client.queryAsync 'DELETE FROM geocaches'
            done()

        it 'should return data from a previous upsert', Promise.coroutine ->
            yield geocaches.upsert GC1BAZ8
            gc = yield geocaches.get 'GC1BAZ8'
            # TODO hrm
            delete gc.meta
            expect(gc).to.deep.equal GC1BAZ8

        it 'should accept the id in mixed casing', Promise.coroutine ->
            yield geocaches.upsert GC1BAZ8
            gc = yield geocaches.get 'gc1BAz8'
            expect(gc).to.exist

        it 'should return null if no geocache exists', Promise.coroutine ->
            gc = yield geocaches.get 'non-existing-id'
            expect(gc).to.not.exist
