fs = require 'fs'
program = require 'commander'
Promise = require 'bluebird'
Promise.longStackTraces()

route = require './route'
boundingBox = require './boundingbox'
gcLookup = require './gcLookup'
tiles = require './tiles'

program
    .version '0.0.1'
    .usage '[options] <start lat> <start lon> <dest lat> <dest lon>'
    .option '-v, --verbose', 'Verbose output'
    .option '-z, --zoom <n>', 'Zoom level for tiling algorithm', parseInt
    .option '-o, --output <file>', 'Write geocache ids to this file'
    .parse process.argv

log = (msg) ->
    console.log msg if program.verbose

main = Promise.coroutine () ->
    coordinateArgs = program.args.map parseFloat

    log 'Calculating route...'
    log "Start       #{coordinateArgs[0]} #{coordinateArgs[1]}"
    log "Destination #{coordinateArgs[2]} #{coordinateArgs[3]}"
    coordinates = yield route coordinateArgs...

    log "Calculating tiles of #{coordinates.length} points @ #{program.zoom}..."
    tilesForPath = tiles.coverPath coordinates, program.zoom

    log "Querying #{tilesForPath.length} tiles for geocache information..."
    geocacheIds = yield gcLookup.lookupTiles tilesForPath, (percent) ->
        log percent

    log "Found #{geocacheIds.length} geocaches"

    if program.output?
        fs.writeFileSync program.output, JSON.stringify(geocacheIds), 'utf8'
    else
        console.log JSON.stringify geocacheIds

if program.args.length isnt 4
    program.help()

main()
