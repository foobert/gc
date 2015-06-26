_ = require 'lodash'
Promise = require 'bluebird'

module.exports = (db, view, timeout, debug = null) ->
    refresh = Promise.coroutine ->
        debug 'refresh view' if debug?
        [client, done] = yield db.connect()
        try
            # SQL INJECTION on `view` possible?
            yield client.queryAsync "REFRESH MATERIALIZED VIEW #{view}"
            debug 'refresh view complete' if debug?
        finally
            done()

    _.debounce refresh, timeout
