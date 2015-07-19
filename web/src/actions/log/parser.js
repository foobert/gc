const xml2js = require('xml2js');
const request = require('superagent-as-promised')(require('superagent'));

function read(file) {
    return new Promise(function(resolve, reject) {
        let fileReader = new FileReader();
        fileReader.onload = () => resolve(fileReader.result);
        fileReader.onerror = (err) => reject(err);
        fileReader.onabort = (err) => reject(err);
        fileReader.readAsText(file);
    });
}

function parse(gpx) {
    return new Promise(function(resolve, reject) {
        xml2js.parseString(gpx, (err, json) => {
            if (err)
                return reject(err);
            resolve(json);
        });
    });
}

function getDistance (coord1, coord2) {
    const r = 6371000; // earth radius in meters
    const _toRad = (x) => x * Math.PI / 180;

    const phi1 = _toRad(coord1.lat);
    const phi2 = _toRad(coord2.lat);

    const deltaPhi = _toRad(coord2.lat - coord1.lat);
    const deltaLambda = _toRad(coord2.lon - coord1.lon);

    const a = Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
        Math.cos(phi1) * Math.cos(phi2) *
        Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = r * c;

    return distance;
}

function getBounds(pool) {
    let box = [null, null, null, null];
    for (var coord of pool) {
        if (!box[0] || coord.lat < box[0]) box[0] = coord.lat;
        if (!box[1] || coord.lon < box[1]) box[1] = coord.lon;
        if (!box[2] || coord.lat > box[2]) box[2] = coord.lat;
        if (!box[3] || coord.lon > box[3]) box[3] = coord.lon;
    }
    return box;
}

function widen(box) {
    box[0] -= 0.001;
    box[1] -= 0.001;
    box[2] += 0.001;
    box[3] += 0.001;
}

function getTimestamp(pool) {
    return pool[0];
}

async function getGeocaches(box) {
    const _qs = (key, values) => values.map((v) => `${key}[]=${v}`).join('&');

    if (box[0] > box[2]) {
        let tmp = box[0];
        box[0] = box[2];
        box[2] = tmp;
    }

    if (box[1] > box[3]) {
        let tmp = box[1];
        box[1] = box[3];
        box[2] = tmp;
    }

    let response = await request.get('https://gc.funkenburg.net/api/geocaches')
        .query({excludeDisabled: 0})
        .query(_qs('bounds', box));
    return response.body;
}

module.exports = async function(file) {
    let gpx = await read(file);
    let json = await parse(gpx);
    if (json.gpx.$.xmlns !== 'http://www.topografix.com/GPX/1/1')
        throw new Error('Invalid gpx format');

    let prevCoord = null;
    let prevTime = null;
    let pool = [];
    let matches = {};

    for (var trk of json.gpx.trk) {
        for (var trkseg of trk.trkseg) {
            for (var trkpt of trkseg.trkpt) {
                let coord = {lat: parseFloat(trkpt.$.lat), lon: parseFloat(trkpt.$.lon)};
                let time = new Date(trkpt.time);
                if (prevCoord !== null) {
                    let distance = getDistance(prevCoord, coord);
                    let deltaTime = (time - prevTime) / 1000;
                    let speed = distance / deltaTime;

                    if (speed < 1) {
                        pool.push({coord: coord, time: time});
                    } else {
                        if (pool.length > 10) {
                            let box = getBounds(pool.map((x) => x.coord));
                            widen(box);

                            let timestamp = getTimestamp(pool.map((x) => x.time));
                            let gcs = await getGeocaches(box);
                            for (var gc of gcs) {
                                gc._timestamp = timestamp;
                                matches[gc.Code] = gc;
                            }
                        }
                        pool = [];
                    }
                }
                prevCoord = coord;
                prevTime = time;
            }
        }
    }

    let result = [];
    for (var x in matches) {
        result.push(matches[x]);
    }

    return result;
}
