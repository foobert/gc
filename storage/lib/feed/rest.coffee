async = require '../rest-async'
debug = require('debug') 'gc:feed'
jade = require 'jade'
path = require 'path'
stream = require 'stream'
Promise = require 'bluebird'

names =
    2: 'Traditional'
    3: 'Multi Cache'
    4: 'Virtual Cache'
    5: 'Letterbox'
    6: 'Event Cache'
    8: 'Mystery'
    11: 'Webcam Cache'
    13: 'CITO'
    137: 'Earth Cache'
    453: 'Mega Event'
    1858: 'Wherigo'

formatCoordinates = (latitude, longitude) ->
    convert = (deg) ->
        fullDeg = parseInt deg
        min = (deg - fullDeg) * 60
        "#{fullDeg}' #{min.toFixed 3}"
    latPrefix = if latitude < 0 then 'S' else 'N'
    lonPrefix = if longitude < 0 then 'W' else 'E'
    return "#{latPrefix} #{convert latitude} #{lonPrefix} #{convert longitude}"

formatTypeId = (typeId) ->
    names[typeId] or 'Unknown'

getDistance = (geocache, center) ->
    [lat1, lon1] = center
    r = 6371000 # earth radius in meters

    _toRad = (x) -> x * Math.PI / 180
    phi1 = _toRad lat1
    phi2 = _toRad geocache.Latitude
    deltaPhi = _toRad (geocache.Latitude - lat1)
    deltaLambda = _toRad (geocache.Longitude - lon1)

    a = Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
        Math.cos(phi1) * Math.cos(phi2) *
        Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    distance = r * c

    return distance

class TransformStream extends stream.Transform
    constructor: (mappper) ->
        super objectMode: true
        @updated = false
        @mapper = arguments[0] # wtf?
        @push '<?xml version="1.0" encoding="utf-8" ?>'
        @push '<feed xmlns="http://www.w3.org/2005/Atom">'
        @push '<id>https://gc.funkenburg.net/feed</id>'
        @push '<title type="text">Geocaches</title>'

    _transform: (obj, encoding, cb) ->
        if not @updated
            @updated = true
            cb null, "<updated>#{obj.UTCPlaceDate}</updated>" + @mapper obj
        else
            cb null, @mapper obj

    _flush: (cb) ->
        @push '</feed>'
        cb()

module.exports = (app, geocache) ->
    template = jade.compileFile path.join __dirname, 'view.jade'

    app.get '/feed', async (req, res, next) ->
        res.set 'Content-Type', 'application/atom+xml'

        stream = yield geocache.getStream
            maxAge: 30
            orderBy: 'UTCPlaceDate'
            order: 'desc'
        , true

        if req.query.homeLat? and req.query.homeLon?
            homeCoords = [parseFloat(req.query.homeLat), parseFloat(req.query.homeLon)]

        render = (geocache) ->
            geocache.Distance = getDistance geocache, homeCoords if homeCoords?
            geocache.Coordinates = formatCoordinates geocache.Latitude, geocache.Longitude
            geocache.CacheType.GeocacheTypeName = formatTypeId geocache.CacheType.GeocacheTypeId
            template
                geocache: geocache

        stream
            .pipe new TransformStream render
            .pipe res
