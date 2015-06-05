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

getType = (gc) ->
    switch gc.CacheType.GeocacheTypeId
        when   2 then 'T'
        when   3 then 'M'
        when   5 then 'L'
        when  11 then 'W'
        when 137 then 'E'
        else '?'

getCode = (gc) ->
    gc.Code[2..-1]

getSkill = (gc) ->
    "#{gc.Difficulty}/#{gc.Terrain}"

getSize = (gc) ->
    gc.ContainerType.ContainerTypeName[0]

getName = (gc) ->
    clean gc.Name

getHint = (gc) ->
    clean gc.EncodedHints ? ''

module.exports =
    title: (gc) ->
        "#{getCode gc} #{getSize gc} #{getType gc} #{getSkill gc}"

    description: (gc) ->
        "#{getName gc}\n#{getHint gc}"[0...100]
