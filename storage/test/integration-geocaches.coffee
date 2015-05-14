{expect} = require 'chai'
Promise = require 'bluebird'
request = require 'superagent-as-promised'

url = 'http://localhost:8081'
token = 'b4e124aa-96d9-4774-9565-b7e728561e4c'

setupDatabase = Promise.coroutine (geocaches) ->
    response = yield request
        .del  "#{url}/geocaches"
        .set 'X-Token', token
    expect(response.status).to.equal 202

    response = yield request
        .put "#{url}/geocaches"
        .set 'Content-Type', 'application/json'
        .set 'X-Token', token
        .send geocaches
    expect(response.status).to.equal 201

gc = (id, options) ->
    defaults =
        Code: "GC#{id}"
        Latitude: 10
        Longitude: 20
        Archived: false
        Available: true
        CacheType:
            GeocacheTypeId: 1
        UTCPlaceDate: "/Date(#{new Date().getTime()}-0000)/"
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

describe 'REST routes for geocaches', ->
    before Promise.coroutine ->
        yield setupDatabase []

    describe '/gcs', ->
        it 'should return a list of GC numbers on GET', Promise.coroutine ->
            yield setupDatabase [
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
            yield setupDatabase [
                gc '100',
                    UTCPlaceDate: "/Date(#{new Date().getTime()}-0000)/"
                gc '101',
                    UTCPlaceDate: '/Date(946684800-0000)/'
            ]
            response = yield request
                .get "#{url}/gcs"
                .query maxAge: 1
                .set 'Accept', 'application/json'
            expect(response.type).to.equal 'application/json'
            expect(response.body.length).to.equal 1
            expect(response.body).to.include.members ['GC100']

        it 'should filter by coordinates using "bounds"', Promise.coroutine ->
            yield setupDatabase [
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
            yield setupDatabase [
                gc '100',
                    CacheType:
                        GeocacheTypeId: 5
                gc '101',
                    CacheType:
                        GeocacheTypeId: 6
                gc '102',
                    CacheType:
                        GeocacheTypeId: 7
            ]
            response = yield request
                .get "#{url}/gcs"
                .query typeIds: [5, 7]
                .set 'Accept', 'application/json'
            expect(response.type).to.equal 'application/json'
            expect(response.body.length).to.equal 2
            expect(response.body).to.include.members ['GC100', 'GC102']

        it 'should filter disabled/archived geocaches using "excludeDisabled"', Promise.coroutine ->
            yield setupDatabase [
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
            yield setupDatabase [
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
            yield setupDatabase [
                gc '100',
                    meta:
                        updated: new Date().toISOString()
                gc '101',
                    meta:
                        updated: '2000-01-01 00:00:00Z'
            ]
            response = yield request
                .get "#{url}/gcs"
                .set 'Accept', 'application/json'
            expect(response.type).to.equal 'application/json'
            expect(response.body.length).to.equal 1
            expect(response.body).to.include.members ['GC100']

        it 'should return stale geocaches when "stale" is 1', Promise.coroutine ->
            yield setupDatabase [
                gc '100',
                    updated: new Date().toISOString()
                gc '101',
                    updated: '2000-01-01 00:00:00Z'
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
            a = gc '100', meta: updated: new Date().toISOString()
            b = gc '101', meta: updated: new Date().toISOString()
            yield setupDatabase [a, b]
            response = yield request
                .get "#{url}/geocaches"
                .set 'Accept', 'application/json'

            expect(response.type).to.equal 'application/json'
            expect(response.body.length).to.equal 2
            expect(response.body).to.deep.include.members [a, b]

        it 'should include the update timestamp', Promise.coroutine ->
            a = gc '100', meta: updated: new Date().toISOString()
            yield setupDatabase [a]
            response = yield request
                .get "#{url}/geocaches"
                .set 'Accept', 'application/json'

            expect(response.body[0].meta.updated).to.equal a.meta.updated

        it 'should create new geocaches on POST', Promise.coroutine ->
            yield setupDatabase []

            a = gc '100', meta: updated: new Date().toISOString()

            putResponse = yield request
                .put "#{url}/geocaches"
                .set 'Content-Type', 'application/json'
                .set 'X-Token', token
                .send [a]

            getResponse = yield request
                .get "#{url}/geocaches"
                .set 'Accept', 'application/json'

            expect(getResponse.body).to.deep.equal [a]

        it 'should should reject POSTs without a valid API key', Promise.coroutine ->
            yield setupDatabase []

            a = gc '100', meta: updated: new Date().toISOString()

            try
                putResponse = yield request
                    .put "#{url}/geocaches"
                    .set 'Content-Type', 'application/json'
                    .set 'X-Token', 'invalid'
                    .send [a]
            catch err

            expect(err.status).to.equal 403

            getResponse = yield request
                .get "#{url}/geocaches"
                .set 'Accept', 'application/json'

            expect(getResponse.body).to.deep.equal []

        it 'should should reject POSTs with a missing API key', Promise.coroutine ->
            yield setupDatabase []

            a = gc '100', meta: updated: new Date().toISOString()

            try
                putResponse = yield request
                    .put "#{url}/geocaches"
                    .set 'Content-Type', 'application/json'
                    .send [a]
            catch err

            expect(err.status).to.equal 403

            getResponse = yield request
                .get "#{url}/geocaches"
                .set 'Accept', 'application/json'

            expect(getResponse.body).to.deep.equal []
