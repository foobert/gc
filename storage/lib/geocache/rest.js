/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const async2 = require('../rest-async');
const JSONStream = require('JSONStream');
const Promise = require('bluebird');

const etag = function(gc) {
    // use momentjs?
    if (gc == null) { return null; }
    const time = gc.DateLastUpdate;
    const match = time != null ? time.match(/^\/Date\((\d+)-(\d{2})(\d{2})\)\/$/) : undefined;
    if (match == null) { return null; }
    const seconds_epoch = parseInt(match[1]) / 1000;
    const timezone_hours = parseInt(match[2]) * 60 * 60;
    const timezone_minutes = parseInt(match[3]) * 60;
    return new Date((seconds_epoch - timezone_hours - timezone_minutes) * 1000).toISOString();
};

module.exports = function(app, geocache) {
    app.get('/geocaches', async function(req, res, next) {
        res.set('Content-Type', 'application/json; charset=utf-8');
        const geocacheStream = await geocache.getStream(req.query, true);
        geocacheStream
            .pipe(JSONStream.stringify('[', ',', ']'))
            .pipe(res);
    });

    app.get('/geocaches?/:gc', async function(req, res, next) {
        const gc = await geocache.get(req.params.gc);
        if (gc == null) {
            res.status(404);
            res.send('404 - Geocache not found\n');
        } else {
            res.set('ETag', etag(gc));
            res.set('Content-Type', 'application/json; charset=utf-8');
            res.json(gc);
        }
    });

    app.head('/geocache/:gc', async function(req, res, next) {
        const gc = await geocache.get(req.params.gc);
        if (gc == null) {
            res.status(404);
            res.send('404 - Geocache not found\n');
        } else {
            res.set('ETag', etag(gc));
            res.status(204);
        }
    });

    app.post('/geocache', async function(req, res, next) {
        await geocache.upsert(req.body);
        res.status(201);
        // TODO return upserted gc document
        res.send('');
    });

    app.get('/geocache/:gc/seen', async function(req, res, next) {
        const gc = await geocache.get(req.params.gc);
        res.status(200);
        res.send(gc.meta.updated);
    });

    app.put('/geocache/:gc/seen', async function(req, res, next) {
        const now = Date.parse(req.body);
        await geocache.touch(req.params.gc);
        res.set('Content-Type', 'text/plain; charset=utf-8');
        res.status(200);
        res.send(now);
    });

    app.delete('/geocaches', async function(req, res, next) {
        await geocache.deleteAll();
        res.status(204);
        res.send('');
    });

    app.delete('/geocaches/:gc', async function(req, res, next) {
        await geocache.delete(req.params.gc);
        res.status(204);
        res.send('');
    });

    app.get('/gcs', async function(req, res, next) {
        res.set('Content-Type', 'application/json; charset=utf-8');
        const gcStream = await geocache.getStream(req.query, false);
        return gcStream
            .pipe(JSONStream.stringify('[', ',', ']'))
            .pipe(res);
    });
};