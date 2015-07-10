Promise = require 'bluebird'

module.exports = (f) ->
    Promise.coroutine (req, res, next) ->
        try
            yield from f req, res, next
        catch err
            next err
