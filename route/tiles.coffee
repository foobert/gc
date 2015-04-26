debug = require('debug')('gc.route.tiles')

getTile = (lat, lon, zoom) ->
    latRad = lat * Math.PI / 180
    n = Math.pow 2, zoom
    x = parseInt((lon + 180.0) / 360.0 * n)
    y = parseInt((1.0 - Math.log(Math.tan(latRad) + (1 / Math.cos(latRad))) / Math.PI) / 2.0 * n)
    return [x, y, zoom]

getCoordinates = (x, y, zoom) ->
    n = Math.pow 2, zoom
    lon = x / n * 360 - 180
    latRad = Math.atan(Math.sinh(Math.PI * (1 - 2 * y / n)))
    lat = latRad / Math.PI * 180
    return [lat, lon]

getBoundingBox = (x, y, zoom) ->
    topLeft = getCoordinates x, y, zoom
    bottomRight = getCoordinates x + 1, y + 1, zoom
    return topLeft.concat bottomRight

getTiles = (top, left, bottom, right, zoom) ->
    [top, bottom] = [bottom, top] if top < bottom
    [left, right] = [right, left] if right < left
    zoom = 1 if zoom < 1

    topLeft = getTile top, left, zoom
    bottomRight = getTile bottom, right, zoom

    if topLeft[0] is bottomRight[0]
        # same x
        if topLeft[1] is bottomRight[1]
            # same x and y -> just one tile
            debug "one tile: #{topLeft}"
            return [topLeft]
        else
            # same x, different y
            x = topLeft[0]
            return ([x, y, zoom] for y in [topLeft[1] ... bottomRight[1]])
    else
        # different x
        if topLeft[1] is bottomRight[1]
            # different x, same y
            y = topLeft[1]
            return ([x, y, zoom] for x in [topLeft[0] ... bottomRight[0]])
        else
            # all different
            debug "all different from #{topLeft} to #{bottomRight}"
            tiles = []
            for x in [topLeft[0] ... bottomRight[0]]
                for y in [topLeft[1] ... bottomRight[1]]
                    tiles.push [x, y, zoom]
            return tiles

getNeighborTiles = (x, y, z) ->
    return ([x+i, y+j, z] for i in [-1, 0, 1] for j in [-1, 0, 1]).reduce (a, b) -> a.concat b


coverPath = (coordinates, zoom) ->
    # this could also use quad tiles?
    # http://wiki.openstreetmap.org/wiki/QuadTiles

    tiles = {}
    for coordinate in coordinates
        tile = getTile coordinate[0], coordinate[1], zoom
        key = JSON.stringify tile
        tiles[key] = {}

        for neighbor in getNeighborTiles tile...
            key = JSON.stringify neighbor
            tiles[key] = {}

    return Object
        .keys tiles
        .map JSON.parse

module.exports = {
    getTile,
    getTiles,
    getCoordinates,
    getBoundingBox,
    getNeighborTiles,
    coverPath
}
