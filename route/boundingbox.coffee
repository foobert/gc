debug = require('debug')('gc.route.boundingbox')

scale = 100
gridsize = 0.05 * scale

truncate = (point) ->
    lat = parseInt(point[0] * scale / gridsize) * gridsize
    lon = parseInt(point[1] * scale / gridsize) * gridsize
    [lat, lon]

untruncate = (box) ->
    return {
        top: box.top / scale
        bottom: box.bottom / scale
        left: box.left / scale
        right: box.right / scale
    }


makeRect = (point) ->
    lat = point[0]
    lon = point[1]
    return {
        top: lat
        bottom: lat - gridsize
        left: lon
        right: lon + gridsize
    }

neighborhood = (point) ->
    a = point[0]
    b = point[1]
    result = []
    for i in [-1, 0, 1]
        for j in [-1, 0, 1]
            result.push makeRect [a+(i*gridsize), b+(j*gridsize)]
    result

toKey = JSON.stringify
fromKey = JSON.parse

setToArray = (set) ->
    result = []
    it = set.values()
    while not (x = it.next()).done
        result.push fromKey x.value
    result

iter = (set, cb) ->
    it = set.values()
    while not (x = it.next()).done
        cb x.value
    set

mergeHorizontal = (grid) ->
    tmp = grid.slice()
    tryMerge = ->
        for box in tmp
            for other in tmp
                if box isnt other and
                   box.top is other.top and box.bottom is other.bottom
                    if box.right is other.left
                        box.right = other.right
                        tmp.splice tmp.indexOf(other), 1
                        return true
                    else if box.left is other.right
                        box.left = other.left
                        tmp.splice tmp.indexOf(other), 1
                        return true
        return false
    while true
        break if not tryMerge()
    return tmp

mergeVertical = (grid) ->
    tmp = grid.slice()
    tryMerge = ->
        for box in tmp
            for other in tmp
                if box isnt other and
                   box.left is other.left and box.right is other.right
                    if box.top is other.bottom
                        box.top = other.top
                        tmp.splice tmp.indexOf(other), 1
                        return true
                    else if box.bottom is other.top
                        box.bottom = other.bottom
                        tmp.splice tmp.indexOf(other), 1
                        return true
        return false
    while true
        break if not tryMerge()
    return tmp

boundingBox = (coordinates) ->
    initialGrid = new Set
    coordinates.forEach (point) ->
        index = truncate point
        initialGrid.add toKey index

    extendedGrid = new Set
    iter initialGrid, (point) ->
        for n in neighborhood fromKey point
            extendedGrid.add toKey n
    grid = setToArray(extendedGrid)

    debug "Coordinates: #{coordinates.length}"
    debug "Truncated: #{initialGrid.size}"
    debug "Extended: #{extendedGrid.size}"

    versionA = mergeVertical mergeHorizontal grid
    versionB = mergeHorizontal mergeVertical grid

    if versionA.length <= versionB.length
        debug "Selected a: #{versionA.length}"
        winner = versionA
    else
        debug "Selected b: #{versionB.length}"
        winner = versionB
    return winner
        .map (box) ->
            untruncate box
        .map (box) ->
            [box.top, box.left, box.bottom, box.right]

module.exports = boundingBox
