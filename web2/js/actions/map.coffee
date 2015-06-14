{Actions} = require 'flummox'
jquery = require 'jquery'

class MapActions extends Actions
    setCenter: (center) ->
        center

    setZoom: (zoom) ->
        zoom

    setBounds: (bounds) ->
        new Promise (resolve, reject) ->
            minll = bounds.getSouthWest()
            maxll = bounds.getNorthEast()
            url = 'https://gc.funkenburg.net/api'
            url += "/geocaches?excludeDisabled=1&bounds[]=#{minll.lat}&bounds[]=#{minll.lng}&bounds[]=#{maxll.lat}&bounds[]=#{maxll.lng}"
            jquery.get url
                .done (geocaches) -> resolve geocaches
                .fail (err) -> reject err

module.exports = MapActions
