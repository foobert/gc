{expect} = require 'chai'
uuid = require 'uuid'
Promise = require 'bluebird'
Promise.longStackTraces()

describe 'access service', ->
    @timeout 5000

    access = null

    before Promise.coroutine ->
        db = require('../lib/db')
            host: process.env.DB_PORT_5432_TCP_ADDR ? 'localhost'
            user: process.env.DB_USER ? 'postgres'
            password: process.env.DB_PASSWORD
            database: process.env.DB ? 'gc'
        yield db.up()
        access = require('../lib/access') db

    describe 'init', ->
        it 'should return a token', Promise.coroutine ->
            token = yield access.init()
            expect(token).to.exist

    describe 'initialized', ->
        before Promise.coroutine ->
            yield access.init()

        describe 'getToken', ->
            it 'should return a token', Promise.coroutine ->
                token = yield access.getToken()
                expect(token).to.exist

        describe 'addToken', ->
            it 'should return a valid token', Promise.coroutine ->
                token = yield access.addToken()
                expect(yield access.check token).to.be.true

        describe 'check', ->
            it 'should return true for a valid token', Promise.coroutine ->
                token = yield access.getToken()
                result = yield access.check token
                expect(result).to.be.true

            it 'should return false for an invalid token', Promise.coroutine ->
                result = yield access.check uuid()
                expect(result).to.be.false

            it 'should return false for a null token', Promise.coroutine ->
                result = yield access.check null
                expect(result).to.be.false
