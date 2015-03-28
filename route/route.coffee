debug = require('debug')('gc.route.route')
Promise = require 'bluebird'
request = require 'superagent'
Promise.promisifyAll request

calculateRoute = Promise.coroutine (
    startLatitude, startLongitude,
    destinationLatitude, destinationLongitude) ->

    debug "querying routing information " +
        "from [#{startLatitude}, #{startLongitude}] " +
        "to [#{destinationLatitude}, #{destinationLongitude}]"

    response = yield request
        .get "http://www.yournavigation.org/api/1.0/gosmore.php"
        .query
            flat: startLatitude
            flon: startLongitude
            tlat: destinationLatitude
            tlon: destinationLongitude
            v: 'motorcar'
            fast: 1
            layer: 'mapnik'
            format: 'geojson'
            geometry: 1
            instructions: 0
        .endAsync()

    points = response.body.coordinates.map (x) -> x.reverse()

    debug "route consists of #{points.length} points"
    return points

module.exports = calculateRoute
