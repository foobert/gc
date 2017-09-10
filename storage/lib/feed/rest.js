/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const async = require('../rest-async');
const debug = require('debug')('gc:feed');
const jade = require('jade');
const path = require('path');
let stream = require('stream');
const Promise = require('bluebird');

const names = {
    2: 'Traditional',
    3: 'Multi Cache',
    4: 'Virtual Cache',
    5: 'Letterbox',
    6: 'Event Cache',
    8: 'Mystery',
    11: 'Webcam Cache',
    13: 'CITO',
    137: 'Earth Cache',
    453: 'Mega Event',
    1858: 'Wherigo'
};

const formatCoordinates = function(latitude, longitude) {
    const convert = function(deg) {
        const fullDeg = parseInt(deg);
        const min = (deg - fullDeg) * 60;
        return `${fullDeg}' ${min.toFixed(3)}`;
    };
    const latPrefix = latitude < 0 ? 'S' : 'N';
    const lonPrefix = longitude < 0 ? 'W' : 'E';
    return `${latPrefix} ${convert(latitude)} ${lonPrefix} ${convert(longitude)}`;
};

const formatTypeId = typeId => names[typeId] || 'Unknown';

const getDistance = function(geocache, center) {
    const [lat1, lon1] = Array.from(center);
    const r = 6371000; // earth radius in meters

    const _toRad = x => (x * Math.PI) / 180;
    const phi1 = _toRad(lat1);
    const phi2 = _toRad(geocache.Latitude);
    const deltaPhi = _toRad((geocache.Latitude - lat1));
    const deltaLambda = _toRad((geocache.Longitude - lon1));

    const a = (Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2)) +
        (Math.cos(phi1) * Math.cos(phi2) *
        Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2));
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = r * c;

    return distance;
};

class TransformStream extends stream.Transform {
    constructor(mappper) {
        super({objectMode: true});
        this.updated = false;
        this.mapper = arguments[0]; // wtf?
        this.push('<?xml version="1.0" encoding="utf-8" ?>');
        this.push('<feed xmlns="http://www.w3.org/2005/Atom">');
        this.push('<id>https://gc.funkenburg.net/feed</id>');
        this.push('<title type="text">Geocaches</title>');
    }

    _transform(obj, encoding, cb) {
        if (!this.updated) {
            this.updated = true;
            return cb(null, `<updated>${obj.UTCPlaceDate}</updated>` + this.mapper(obj));
        } else {
            return cb(null, this.mapper(obj));
        }
    }

    _flush(cb) {
        this.push('</feed>');
        return cb();
    }
}

module.exports = function(app, geocache) {
    const template = jade.compileFile(path.join(__dirname, 'view.jade'));

    return app.get('/feed', async(function*(req, res, next) {
        let homeCoords;
        res.set('Content-Type', 'application/atom+xml');

        stream = yield geocache.getStream({
            maxAge: 30,
            orderBy: 'UTCPlaceDate',
            order: 'desc'
        }
        , true);

        if ((req.query.homeLat != null) && (req.query.homeLon != null)) {
            homeCoords = [parseFloat(req.query.homeLat), parseFloat(req.query.homeLon)];
        }

        const render = function(geocache) {
            if (homeCoords != null) { geocache.Distance = getDistance(geocache, homeCoords); }
            geocache.Coordinates = formatCoordinates(geocache.Latitude, geocache.Longitude);
            geocache.CacheType.GeocacheTypeName = formatTypeId(geocache.CacheType.GeocacheTypeId);
            return template({
                geocache});
        };

        return stream
            .pipe(new TransformStream(render))
            .pipe(res);
    })
    );
};
