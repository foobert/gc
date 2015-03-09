express = require 'express'
jade = require 'jade'
request = require 'superagent-as-promised'
debug = require('debug')('gc.feed')
Promise = require 'bluebird'

app = express()

server = process.env['API'] || 'http://localhost/api/'
self = process.env['SELF'] || 'http://localhost/feed'

template = jade.compileFile 'views/feed.jade'

lastFetch = null
geocaches = null

debug "using API server at #{server}"
debug "using self URL #{self}"

parseTime = (time) ->
    match = time.match /^\/Date\((\d+)-(\d{2})(\d{2})\)\/$/
    return null unless match?
    seconds_epoch = parseInt(match[1]) / 1000
    timezone_hours = parseInt(match[2]) * 60 * 60
    timezone_minutes = parseInt(match[3]) * 60
    new Date((seconds_epoch - timezone_hours - timezone_minutes) * 1000).toISOString()

fixTimestamps = (geocaches) ->
    geocaches.forEach (geocache) ->
        geocache.UTCPlaceDate = parseTime geocache.UTCPlaceDate

app.get '/*', Promise.coroutine (req, res, next) ->

    if not geocaches? or not lastFetch? or new Date - lastFetch > 60000
        debug 'fetching geocaches'
        try
            apiRes = yield request
                .get "#{server}/geocaches"
                .accept 'application/json'
                .query
                    full: 1
                    maxAge: 14
            geocaches = apiRes.body
            fixTimestamps geocaches
            lastFetch = new Date
        catch e
            console.error "Unable to get upstream geocaches: #{e}"
            res.status 500
            res.send 'Failed to get upstream data'
            return

    xml = template
        self: self
        updated: '2015-01-01'
        geocaches: geocaches
    res.set 'Content-Type', 'application/atom+xml'
    res.send xml

app.set 'x-powered-by', false
app.listen 8081
