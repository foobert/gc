fs = require 'fs'
Promise = require 'bluebird'
{expect} = require 'chai'

describe 'geocache service', ->
    db = null
    geocaches = null

    GC1BAZ8 = null
    GC38XPR = null

    before Promise.coroutine ->
        db = require('../lib/db')
            host: process.env.DB_PORT_5432_TCP_ADDR ? 'localhost'
            user: process.env.DB_USER ? 'postgres'
            password: process.env.DB_PASSWORD
            database: process.env.DB ? 'gc'
        yield db.up()
        geocaches = require('../lib/geocache') db

        GC1BAZ8 = JSON.parse fs.readFileSync "#{__dirname}/data/GC1BAZ8", 'utf8'
        GC38XPR = JSON.parse fs.readFileSync "#{__dirname}/data/GC38XPR", 'utf8'

    beforeEach Promise.coroutine ->
        [client, done] = yield db.connect()
        yield client.queryAsync 'DELETE FROM geocaches'
        done()

    describe 'get', ->
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

    describe 'upsert', ->
        it 'should overwrite a previous geocache', Promise.coroutine ->
            copy = JSON.parse JSON.stringify GC1BAZ8
            copy.Name = 'new name'

            yield geocaches.upsert GC1BAZ8
            yield geocaches.upsert copy
            gc = yield geocaches.get 'GC1BAZ8'

            expect(gc.Name).to.equal 'new name'

        it 'should update the updated field', Promise.coroutine ->
            yield geocaches.upsert GC1BAZ8
            oldGc = yield geocaches.get 'GC1BAZ8'

            # Make sure we actually get some delay in the updated value ;-)
            yield Promise.delay 20

            yield geocaches.upsert GC1BAZ8
            newGc = yield geocaches.get 'GC1BAZ8'

            expect(newGc.meta.updated.getTime()).to.be.greaterThan oldGc.meta.updated.getTime()

    describe 'touch', ->
        oldGc = null
        beforeEach Promise.coroutine ->
            yield geocaches.upsert GC1BAZ8
            oldGc = yield geocaches.get 'GC1BAZ8'

        it 'should update the updated field', Promise.coroutine ->
            # Make sure we actually get some delay in the updated value ;-)
            yield Promise.delay 20

            yield geocaches.touch 'GC1BAZ8'
            newGc = yield geocaches.get 'GC1BAZ8'

            expect(newGc.meta.updated.getTime()).to.be.greaterThan oldGc.meta.updated.getTime()

        it 'should update the updated field to a given date', Promise.coroutine ->
            # Make sure we actually get some delay in the updated value ;-)
            yield Promise.delay 20

            updated = new Date '2015-01-01 06:00Z'
            yield geocaches.touch 'GC1BAZ8', updated
            newGc = yield geocaches.get 'GC1BAZ8'

            expect(newGc.meta.updated.getTime()).to.be.equal updated.getTime()

        it 'should do nothing if the geocache does not exist', Promise.coroutine ->
            yield geocaches.touch 'non-existing-id'

    describe 'delete', ->
        it 'should delete a geocache', Promise.coroutine ->
            yield geocaches.upsert GC1BAZ8
            yield geocaches.delete 'GC1BAZ8'
            gc = yield geocaches.get 'GC1BAZ8'
            expect(gc).to.not.exist

        it 'should accept mixed case ids', Promise.coroutine ->
            yield geocaches.upsert GC1BAZ8
            yield geocaches.delete 'gc1BAz8'
            gc = yield geocaches.get 'GC1BAZ8'
            expect(gc).to.not.exist

        it 'should do nothing if the geoache does not exist', Promise.coroutine ->
            yield geocaches.delete 'non-existing-id'

    describe 'deleteAll', ->
        it 'should delete all geocaches', Promise.coroutine ->
            yield geocaches.upsert GC1BAZ8
            yield geocaches.upsert GC38XPR
            yield geocaches.deleteAll()
            expect(yield geocaches.get 'GC1BAZ8').to.not.exist
            expect(yield geocaches.get 'GC38XPR').to.not.exist

        it 'should do nothing if no geocaches exist', Promise.coroutine ->
            yield geocaches.deleteAll()
