{expect} = require 'chai'
Promise = require 'bluebird'
request = require 'superagent-as-promised'

access = require '../lib/access'
geocacheService = require '../lib/geocache'

describe 'REST routes for geocaches', ->
    @timeout 5000

    db = null
    token = null
    url = null

    setupTestData = Promise.coroutine (geocaches) ->
        geocaches = JSON.parse JSON.stringify geocaches
        g = geocacheService db
        yield g.deleteAll()
        for geocache in geocaches
            yield g.upsert geocache
        yield g.forceRefresh()

    gc = (id, options) ->
        defaults =
            Code: "GC#{id}"
            Name: 'geocache name'
            Latitude: 10
            Longitude: 20
            Terrain: 1
            Difficulty: 1
            Archived: false
            Available: true
            CacheType: GeocacheTypeId: 2
            ContainerType: ContainerTypeName: 'Micro'
            UTCPlaceDate: "/Date(#{new Date().getTime()}-0000)/"
            EncodedHints: 'some hints'
        merge = (a, b) ->
            return a unless b?
            for k, v of b
                if typeof v is 'object'
                    a[k] = {} unless a[k]?
                    merge a[k], v
                else
                    a[k] = v
            a

        merge defaults, options

    before Promise.coroutine ->
        url = "http://#{process.env.APP_PORT_8081_TCP_ADDR}:#{process.env.APP_PORT_8081_TCP_PORT}"
        db = require('../lib/db')
            host: process.env.DB_PORT_5432_TCP_ADDR ? 'localhost'
            user: process.env.DB_USER ? 'postgres'
            password: process.env.DB_PASSWORD
            database: process.env.DB ? 'gc'

        a = access db
        token = yield a.getToken()

        tries = 5
        appRunning = false
        while tries-- > 0
            try
                response = yield request.get url
                if response.status is 200
                    console.log "found app at #{url}"
                    appRunning = true
                    break
                yield Promise.delay 1000
            catch err
                yield Promise.delay 1000

        if not appRunning
            throw new Error "App is not running at #{url}"

    beforeEach Promise.coroutine ->
        yield setupTestData []

    describe '/gcs', ->
        it 'should return a list of GC numbers on GET', Promise.coroutine ->
            yield setupTestData [
                gc '100'
                gc '101'
            ]
            response = yield request
                .get "#{url}/gcs"
                .set 'Accept', 'application/json'
            expect(response.type).to.equal 'application/json'
            expect(response.body.length).to.equal 2
            expect(response.body).to.include.members ['GC100', 'GC101']

        it 'should filter by age using "maxAge"', Promise.coroutine ->
            yield setupTestData [
                gc '100', UTCPlaceDate: "/Date(#{new Date().getTime()}-0000)/"
                gc '101', UTCPlaceDate: '/Date(00946684800-0000)/'
            ]
            response = yield request
                .get "#{url}/gcs"
                .query maxAge: 1
                .set 'Accept', 'application/json'
            expect(response.type).to.equal 'application/json'
            expect(response.body.length).to.equal 1
            expect(response.body).to.include.members ['GC100']

        it 'should filter by coordinates using "bounds"', Promise.coroutine ->
            yield setupTestData [
                gc '100',
                    Latitude: 10
                    Longitude: 10
                gc '101',
                    Latitude: 10
                    Longitude: 11
                gc '102',
                    Latitude: 11
                    Longitude: 10
                gc '103',
                    Latitude: 11
                    Longitude: 11
            ]
            response = yield request
                .get "#{url}/gcs"
                .query bounds: [9.5, 9.5, 10.5, 10.5]
                .set 'Accept', 'application/json'
            expect(response.type).to.equal 'application/json'
            expect(response.body.length).to.equal 1
            expect(response.body).to.include.members ['GC100']

        it 'should filter by type id using "typeIds"', Promise.coroutine ->
            yield setupTestData [
                gc '100', CacheType: GeocacheTypeId: 5
                gc '101', CacheType: GeocacheTypeId: 6
                gc '102', CacheType: GeocacheTypeId: 7
            ]
            response = yield request
                .get "#{url}/gcs"
                .query typeIds: [5, 7]
                .set 'Accept', 'application/json'
            expect(response.type).to.equal 'application/json'
            expect(response.body.length).to.equal 2
            expect(response.body).to.include.members ['GC100', 'GC102']

        it 'should filter disabled/archived geocaches using "excludeDisabled"', Promise.coroutine ->
            yield setupTestData [
                gc '100',
                    Archived: false
                    Available: false
                gc '101',
                    Archived: false
                    Available: true
                gc '102',
                    Archived: true
                    Available: false
                gc '103',
                    Archived: true
                    Available: true
            ]
            response = yield request
                .get "#{url}/gcs"
                .query excludeDisabled: 1
                .set 'Accept', 'application/json'
            expect(response.type).to.equal 'application/json'
            expect(response.body.length).to.equal 1
            expect(response.body).to.include.members ['GC101']

        it 'should return disabled/archived geocaches by default', Promise.coroutine ->
            yield setupTestData [
                gc '100',
                    Archived: false
                    Available: false
                gc '101',
                    Archived: false
                    Available: true
                gc '102',
                    Archived: true
                    Available: false
                gc '103',
                    Archived: true
                    Available: true
            ]
            response = yield request
                .get "#{url}/gcs"
                .set 'Accept', 'application/json'
            expect(response.type).to.equal 'application/json'
            expect(response.body.length).to.equal 4
            expect(response.body).to.include.members ['GC100', 'GC101', 'GC102', 'GC103']


        it 'should filter stale geocaches by default', Promise.coroutine ->
            yield setupTestData [
                gc '100', meta: updated: new Date().toISOString()
                gc '101', meta: updated: '2000-01-01 00:00:00Z'
            ]
            response = yield request
                .get "#{url}/gcs"
                .set 'Accept', 'application/json'
            expect(response.type).to.equal 'application/json'
            expect(response.body.length).to.equal 1
            expect(response.body).to.include.members ['GC100']

        it 'should return stale geocaches when "stale" is 1', Promise.coroutine ->
            yield setupTestData [
                gc '100', meta: updated: new Date().toISOString()
                gc '101', meta: updated: '2000-01-01 00:00:00Z'
            ]
            response = yield request
                .get "#{url}/gcs"
                .query stale: 1
                .set 'Accept', 'application/json'
            expect(response.type).to.equal 'application/json'
            expect(response.body.length).to.equal 2
            expect(response.body).to.include.members ['GC100', 'GC101']

    describe '/geocaches', ->
        it 'should return a list of geocaches on GET', Promise.coroutine ->
            a = gc '100'
            b = gc '101'
            yield setupTestData [a, b]
            response = yield request
                .get "#{url}/geocaches"
                .set 'Accept', 'application/json'

            expect(response.type).to.equal 'application/json'
            expect(response.body.length).to.equal 2
            expect(response.body.map (gc) -> gc.Code).to.deep.equal ['GC100', 'GC101']

        [
            name: 'Code'
            type: 'String'
        ,
            name: 'Name'
            type: 'String'
        ,
            name: 'Terrain'
            type: 'Number'
        ,
            name: 'Difficulty'
            type: 'Number'
        ,
            name: 'Archived'
            type: 'Boolean'
        ,
            name: 'UTCPlaceDate'
            type: 'String'
        ].forEach ({name, type}) ->
            it "should include field #{name} of type #{type}", Promise.coroutine ->
                a = gc '100'
                yield setupTestData [a]
                response = yield request
                    .get "#{url}/geocaches"
                    .set 'Accept', 'application/json'

                [result] = response.body
                expect(result[name]).to.exist
                expect(result[name]).to.be.a type

        it 'should include the update timestamp', Promise.coroutine ->
            a = gc '100', meta: updated: new Date().toISOString()
            yield setupTestData [a]
            response = yield request
                .get "#{url}/geocaches"
                .set 'Accept', 'application/json'

            [result] = response.body
            expect(result.meta.updated).to.equal a.meta.updated

        it 'should create new geocaches on POST', Promise.coroutine ->
            a = gc '100', meta: updated: new Date().toISOString()

            putResponse = yield request
                .post "#{url}/geocache"
                .set 'Content-Type', 'application/json'
                .set 'X-Token', token
                .send a

            getResponse = yield request
                .get "#{url}/geocache/GC100"
                .set 'Accept', 'application/json'

            expect(putResponse.status).to.equal 201
            expect(getResponse.status).to.equal 200

        it 'should should reject POSTs without a valid API key', Promise.coroutine ->
            a = gc '100', meta: updated: new Date().toISOString()

            try
                putResponse = yield request
                    .post "#{url}/geocache"
                    .set 'Content-Type', 'application/json'
                    .set 'X-Token', 'invalid'
                    .send a
            catch err
                # expected

            expect(err.status).to.equal 403

            getResponse = yield request
                .get "#{url}/geocaches"
                .set 'Accept', 'application/json'

            expect(getResponse.body).to.deep.equal []

        it 'should should reject POSTs with a missing API key', Promise.coroutine ->
            a = gc '100', meta: updated: new Date().toISOString()

            try
                putResponse = yield request
                    .post "#{url}/geocache"
                    .set 'Content-Type', 'application/json'
                    .send a
            catch err
                # expected

            expect(err.status).to.equal 403

            getResponse = yield request
                .get "#{url}/geocaches"
                .set 'Accept', 'application/json'

            expect(getResponse.body).to.deep.equal []
