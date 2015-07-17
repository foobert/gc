{expect} = require 'chai'
Promise = require 'bluebird'
request = require 'superagent-as-promised'

geocacheService = require '../lib/geocache'

describe 'REST routes for feed', ->
    @timeout 15000

    db = null
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

        tries = 10
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


    describe 'feed', ->
        it 'should send content type application/atom+xml', Promise.coroutine ->
            response = yield request
                .get "#{url}/feed"
                .set 'Accept', 'application/atom+xml'

            expect(response.type).to.equal 'application/atom+xml'

        it 'should be a valid atom document', Promise.coroutine ->
            response = yield request
                .get "#{url}/feed"
                .set 'Accept', 'application/atom+xml'
            console.log response.text

        it 'should have a valid atom header', Promise.coroutine ->
            yield setupTestData [
                gc '100'
                gc '101'
            ]
            response = yield request
                .get "#{url}/feed"
                .set 'Accept', 'application/atom+xml'
            console.log response.body


