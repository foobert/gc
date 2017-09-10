/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const bodyParser = require('body-parser');
const compression = require('compression');
const express = require('express');
const Promise = require('bluebird');

module.exports = function(services) {
    const {access, geocache, geolog} = services;

    const app = express();

    app.set('x-powered-by', false);
    app.set('etag', false);
    app.use(compression());
    app.use(bodyParser.json({limit: '50mb'}));

    app.use(Promise.coroutine(function*(req, res, next) {
        if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
            return next();
        }

        if ((yield access.check(req.get('X-Token')))) {
            return next();
        }

        return res
            .status(403)
            .send('Valid API token required');
    })
    );

    app.use(function(req, res, next) {
        res.set('Access-Control-Allow-Origin', '*');
        res.set('Access-Control-Allow-Methods', 'GET, OPTIONS, HEAD');
        return next();
    });

    app.get('/', function(req, res, next) {
        res.status(200);
        return res.send('Okay');
    });

    require('./geocache/rest')(app, geocache);
    require('./poi/rest')(app, geocache);
    require('./feed/rest')(app, geocache);
    require('./geolog/rest')(app, geolog);

    app.use(function(err, req, res, next) {
        console.error(err.stack);
        res.status(500);
        return res.send(':-(');
    });

    return app;
};
