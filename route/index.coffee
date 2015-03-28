Promise = require 'bluebird'
Promise.longStackTraces()

route = require './route'
boundingBox = require './boundingbox'

main = Promise.coroutine () ->
    coordinates = yield route 51.340925, 12.381962, 52.513731, 13.387211
    boxes = boundingBox coordinates
    console.dir boxes

main()
