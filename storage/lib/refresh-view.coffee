_ = require 'lodash'
Promise = require 'bluebird'

module.exports =
    refresh: Promise.coroutine (db, view, debug) ->
        debug 'refresh view' if debug?
        [client, done] = yield db.connect()
        try
            # SQL INJECTION on `view` possible?
            yield client.queryAsync "REFRESH MATERIALIZED VIEW #{view}"
            debug 'refresh view complete' if debug?
        finally
            done()

    debounce: (db, view, timeout, debug) ->
        _.debounce (=> @refresh db, view, debug), timeout
