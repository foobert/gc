csv = require 'csv'
JSONStream = require 'JSONStream'

async = require '../rest-async'
poi = require './format'
streamTransform = require './transform'
xml = require './xml'

handleCsv = (stream) ->
    stream
        .pipe csv.transform (gc) ->
            [
                gc.Longitude
                gc.Latitude
                poi.title gc
                poi.description gc
            ]
        .pipe csv.stringify()

handleXml = (stream) ->
    pre =  """
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"
version="1.1" creator="cachecache">
"""
    post = '</gpx>'

    stream.pipe xml.transform pre, post, (gc) ->
        wpt:
            $:
                lat: gc.Latitude
                lon: gc.Longitude
            name: poi.title gc
            cmt: poi.description gc
            type: 'Geocache'
        wpt:
            $:
                lat: gc.Latitude
                lon: gc.Longitude
            name: poi.title gc
            cmt: poi.description gc
            type: 'Geocache'

handleJson = (stream) ->
    stream
        .pipe streamTransform (gc) ->
            Code: gc.Code
            Name: gc.Name
            Available: gc.Available
            Archived: gc.Archived
            Difficulty: gc.Diffculty
            Terrain: gc.Terrain
            Latittude: gc.Latitude
            Longitude: gc.Longitude
            CacheType: GeocacheTypeId: gc.CacheType.GeocacheTypeId
            ContainerType: ContainerTypeName: gc.ContainerType.ContainerTypeName
            meta:
                poi:
                    name: poi.title gc
                    description: poi.description gc
        .pipe JSONStream.stringify '[', ',', ']'

module.exports = (app, geocache) ->
    app.get '/poi.csv', async (req, res, next) ->
        stream = yield geocache.getStream req.query, true
        res.set 'Content-Type', 'text/csv'
        handleCsv(stream).pipe res

    app.get '/poi.gpx', async (req, res, next) ->
        stream = yield geocache.getStream req.query, true
        res.set 'Content-Type', 'application/gpx+xml'
        handleXml(stream).pipe res

    app.get '/poi.json', async (req, res, next) ->
        stream = yield geocache.getStream req.query, true
        res.set 'Content-Type', 'application/json'
        handleJson(stream).pipe res
