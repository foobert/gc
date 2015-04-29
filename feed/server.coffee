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

formatCoordinates = (latitude, longitude) ->
    convert = (deg) ->
        fullDeg = parseInt deg
        min = (deg - fullDeg) * 60
        "#{fullDeg}' #{min.toFixed 3}"
    latPrefix = if latitude < 0 then 'S' else 'N'
    lonPrefix = if longitude < 0 then 'W' else 'E'
    return "#{latPrefix} #{convert latitude} #{lonPrefix} #{convert longitude}"

fixupGeocaches = (geocaches) ->
    geocaches.forEach (geocache) ->
        geocache.UTCPlaceDate = parseTime geocache.UTCPlaceDate
        geocache.Coordinates = formatCoordinates geocache.Latitude, geocache.Longitude

_toRad = (x) ->
    x * Math.PI / 180

setDistance = (geocaches, center) ->
    [lat1, lon1] = center
    r = 6371000 # earth radius in meters
    phi1 = _toRad lat1
    geocaches.forEach (geocache) ->
        phi2 = _toRad geocache.Latitude
        deltaPhi = _toRad (geocache.Latitude - lat1)
        deltaLambda = _toRad (geocache.Longitude - lon1)

        a = Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
            Math.cos(phi1) * Math.cos(phi2) *
            Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2)
        c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

        geocache.Distance = r * c

sort = (geocaches) ->
    geocaches.sort (a, b) ->
        if a.UTCPlaceDate < b.UTCPlaceDate
            1
        else if a.UTCPlaceDate == b.UTCPlaceDate
            0
        else
            -1

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
            fixupGeocaches geocaches
            geocaches = sort geocaches

            lastFetch = new Date
        catch e
            console.error "Unable to get upstream geocaches: #{e}"
            res.status 500
            res.send 'Failed to get upstream data'
            return

    if req.query.homeLat? and req.query.homeLon?
        setDistance geocaches, [parseFloat(req.query.homeLat), parseFloat(req.query.homeLon)]

    xml = template
        self: self
        updated: geocaches[0]?.UTCPlaceDate or new Date().toISOString()
        geocaches: geocaches
    res.set 'Content-Type', 'application/atom+xml'
    res.send xml

app.set 'x-powered-by', false
app.listen 8081
