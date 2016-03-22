clean = (s) ->
    s.replace /ä/g, 'ae'
        .replace /ö/g, 'oe'
        .replace /ü/g, 'ue'
        .replace /Ä/g, 'AE'
        .replace /Ö/g, 'OE'
        .replace /Ü/g, 'UE'
        .replace /ß/g, 'ss'
        .replace(/ {2,}/g, ' ')
        .replace(/[^a-zA-Z0-9;:?!,.-=_\/@$%*+()<> |\n]/g, '')
        .trim()

type = (gc) ->
    switch gc.CacheType.GeocacheTypeId
        when   2 then 'T'
        when   3 then 'M'
        when   5 then 'L'
        when  11 then 'W'
        when 137 then 'E'
        else '?'

code = (gc) ->
    gc.Code[2..-1]

skill = (gc) ->
    "#{gc.Difficulty.toFixed 1}/#{gc.Terrain.toFixed 1}"

size = (gc) ->
    gc.ContainerType.ContainerTypeName[0]

updated = (gc) ->
    d = gc.meta.updated.toISOString()
    d[5..6] + d[8..9]

name = (gc) ->
    clean gc.Name

hint = (gc) ->
    clean gc.EncodedHints ? ''

module.exports =
    title: (gc) ->
        "GC#{code gc} #{size gc}#{type gc} #{skill gc}"

    description: (gc) ->
        "#{code gc} #{updated gc} #{name gc}\n#{hint gc}"[0...100]
