pg = require 'pg'
squel = require 'squel'
Promise = require 'bluebird'
Promise.promisifyAll pg

module.exports = (connectionString) ->
    select: squel.select
    insert: squel.insert
    update: squel.update
    delete: squel.delete
    connect: pg.connectAsync.bind pg, connectionString
