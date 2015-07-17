{expect} = require 'chai'
Promise = require 'bluebird'
request = require 'superagent-as-promised'

access = require '../lib/access'
geologService = require '../lib/geolog'

describe 'REST routes for logs', ->
    @timeout 15000

    db = null
    token = null
    url = null

    setupTestData = Promise.coroutine (geologs) ->
        geologs = JSON.parse JSON.stringify geologs
        g = geologService db
        yield g.deleteAll()
        for geolog in geologs
            yield g.upsert geolog

    gl = (id, options) ->
        defaults =
            Code: "GL#{id}"
            CacheCode: 'GC12345'
            Finder: UserName: 'Foobar'
            LogType: WptLogTypeId: 2
            UTCCreateDate: '/Date(1431813667662)/'
            VisitDate: '/Date(1431889200000-0700)/'
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

    describe 'GET /logs/latest', ->
        it 'should get the latest log for the given username', Promise.coroutine ->
            a = gl '100', VisitDate: '/Date(1431889200000-0700)/'
            b = gl '101', VisitDate: '/Date(1421889200000-0700)/'

            yield setupTestData [a, b]

            response = yield request.get "#{url}/logs/latest"
                .query username: 'Foobar'
                .set 'Accept', 'application/json'
            expect(response.status).to.equal 200
            expect(response.text).to.equal 'GL100'

        it 'should accept the username in any case', Promise.coroutine ->
            a = gl '100', VisitDate: '/Date(1431889200000-0700)/'
            yield setupTestData [a]

            response = yield request.get "#{url}/logs/latest"
                .query username: 'foOBar'
                .set 'Accept', 'application/json'
            expect(response.text).to.equal 'GL100'

        it 'should return the latest if no username is given', Promise.coroutine ->
            a = gl '100', VisitDate: '/Date(1431889200000-0700)/'
            yield setupTestData [a]

            response = yield request.get "#{url}/logs/latest"
                .set 'Accept', 'application/json'
            expect(response.status).to.equal 200
            expect(response.text).to.equal 'GL100'

        it 'should return 404 if no logs can be found', Promise.coroutine ->
            try
                yield request.get "#{url}/logs/latest"
                    .query username: 'nobody'
                    .set 'Accept', 'application/json'
                expect(true, 'expected an error').to.be.false
            catch err
                expect(err.status).to.equal 404

    describe 'POST /log', ->
        it 'should create a new log', Promise.coroutine ->
            a = gl '100'
            yield request
                .post "#{url}/log"
                .set 'Content-Type', 'application/json'
                .set 'X-Token', token
                .send a

            [client, done] = yield db.connect()
            try
                result = yield client.queryAsync 'SELECT data FROM logs WHERE lower(id) = \'gl100\''
            finally
                done()

            expect(result.rowCount).to.equal 1
            expect(result.rows[0].data).to.deep.equal a

        it 'should return 201', Promise.coroutine ->
            a = gl '100'
            response = yield request
                .post "#{url}/log"
                .set 'Content-Type', 'application/json'
                .set 'X-Token', token
                .send a
            expect(response.status).to.equal 201
