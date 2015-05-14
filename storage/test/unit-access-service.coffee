{expect} = require 'chai'
Promise = require 'bluebird'
Promise.longStackTraces()

AccessService = require '../access-service'

describe.only 'access service', ->
    accessService = null

    before Promise.coroutine ->
        connectionString = 'postgres://127.0.0.1/gc'
        accessService = new AccessService connectionString
        yield accessService.init()

    describe 'init', ->
        it 'should return a token', Promise.coroutine ->
            token = yield accessService.init()
            expect(token).to.exist

    describe 'getToken', ->
        it 'should return a token', Promise.coroutine ->
            token = yield accessService.getToken()
            expect(token).to.exist

    describe 'addToken', ->
        it 'should return a valid token', Promise.coroutine ->
            token = yield accessService.addToken()
            expect(yield accessService.check token).to.be.true

    describe 'check', ->
        it 'should return true for a valid token', ->
            token = yield accessService.getToken()
            result = yield accessService.check token
            expect(result).to.be.true

        it 'should return false for an invalid token', ->
            result = yield accessService.check 'foo'
            expect(result).to.be.false

        it 'should return false for a null token', ->
            result = yield accessService.check null
            expect(result).to.be.false
