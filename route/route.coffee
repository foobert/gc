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

    # Calculate route using the API from YOURS
    # See http://wiki.openstreetmap.org/wiki/YOURS#Routing_API
    #
    # Other alternatives:
    # http://wiki.openstreetmap.org/wiki/Routing/online_routers
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
