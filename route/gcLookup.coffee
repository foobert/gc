debug = require('debug')('gc.route.gcLookup')
Promise = require 'bluebird'
request = require 'superagent'
Promise.promisifyAll request

zoom = 11
nextTileServer = 1
maxTileServers = 4

toTile = (lat, lon) ->
    latRad = lat * Math.PI / 180
    n = Math.pow 2, zoom
    xtile = parseInt((lon + 180.0) / 360.0 * n)
    ytile = parseInt((1.0 - Math.log(Math.tan(latRad) + (1 / Math.cos(latRad))) / Math.PI) / 2.0 * n)
    return {x: xtile, y: ytile}

parseResponse = (response) ->
    result = {}
    for key, data of response.data
        data.forEach (d) -> result[d.i] = {}
    return Object.keys result

getTileServer = () ->
    #number = Math.floor(Math.random() * (5 - 1)) + 1
    number = nextTileServer
    nextTileServer = nextTileServer % maxTileServers + 1
    return "https://tiles0#{number}.geocaching.com/"

fetch = Promise.coroutine (x, y, z) ->
    server = getTileServer()
    debug "fetching tile #{x}, #{y}, #{z} from #{server}"
    png = yield request
        .get "#{server}/map.png"
        .query
            x: x
            y: y
            z: z
        .endAsync()
    response = yield request
        .get "#{server}/map.info"
        .query
            x: x
            y: y
            z: z
        .endAsync()

    if response.status isnt 200
        debug "got non-200: #{response.status}"
        return []

    result = parseResponse response.body
    debug "found #{result.length} GCs"

    return result

chunk = (arr, size) ->
    chunks = []
    for i in [0 ... arr.length] by size
        chunks.push arr.slice i, i + size
    return chunks

nop = () ->

lookupTiles = Promise.coroutine (tiles, progress = nop) ->
    debug "looking up #{tiles.length} tiles"

    allGCs = []
    done = 0
    for c in chunk tiles, maxTileServers
        allGCs = allGCs.concat yield Promise.all c.map ([x, y, z]) ->
            gcs = fetch x, y, z
            done += 1
            progress done / tiles.length
            return gcs

    if allGCs.length is 0
        return []

    flatGCs = allGCs.reduce (a, b) -> a.concat b
    return flatGCs

lookup = (top, left, bottom, right) ->
    topLeft = toTile top, left
    bottomRight = toTile bottom, right

    tiles = []
    for x in [topLeft.x .. bottomRight.x]
        for y in [topLeft.y .. bottomRight.y]
            tiles.push [x, y, zoom]

    return lookupTiles tiles

module.exports = lookup
module.exports.fetch = fetch
module.exports.parseResponse = parseResponse
module.exports.lookupTiles = lookupTiles
