/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const clean = s =>
    s.replace(/ä/g, 'ae')
        .replace(/ö/g, 'oe')
        .replace(/ü/g, 'ue')
        .replace(/Ä/g, 'AE')
        .replace(/Ö/g, 'OE')
        .replace(/Ü/g, 'UE')
        .replace(/ß/g, 'ss')
        .replace(/ {2,}/g, ' ')
        .replace(/[^a-zA-Z0-9;:?!,.-=_\/@$%*+()<> |\n]/g, '')
        .trim()
;

const type = function(gc) {
    switch (gc.CacheType.GeocacheTypeId) {
        case 2: return 'T';
        case 3: return 'M';
        case 5: return 'L';
        case 11: return 'W';
        case 137: return 'E';
        default: return '?';
    }
};

const code = gc => gc.Code.slice(2);

const skill = gc => `${gc.Difficulty.toFixed(1)}/${gc.Terrain.toFixed(1)}`;

const size = gc => gc.ContainerType.ContainerTypeName[0];

const updated = function(gc) {
    const d = gc.meta.updated.toISOString();
    return d.slice(5, 7) + d.slice(8, 10);
};

const name = gc => clean(gc.Name);

const hint = gc => clean(gc.EncodedHints != null ? gc.EncodedHints : '');

module.exports = {
    title(gc) {
        return `GC${code(gc)} ${size(gc)}${type(gc)} ${skill(gc)}`;
    },

    description(gc) {
        return `${code(gc)} ${updated(gc)} ${name(gc)}\n${hint(gc)}`.slice(0, 100);
    }
};
