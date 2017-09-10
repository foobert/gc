#!/usr/bin/env node
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Promise = require('bluebird');
Promise.longStackTraces();

(Promise.coroutine(function*() {
    const db = require('./lib/db')({
        host: process.env.DB_PORT_5432_TCP_ADDR != null ? process.env.DB_PORT_5432_TCP_ADDR : 'localhost',
        user: process.env.DB_USER != null ? process.env.DB_USER : 'postgres',
        password: process.env.DB_PASSWORD,
        database: process.env.DB != null ? process.env.DB : 'gc'
    });
    yield db.up();

    const access = require('./lib/access')(db);
    const token = yield access.init();
    console.log(`Token: ${token}`);

    const app = require('./lib/rest')({
        access,
        geocache: require('./lib/geocache')(db),
        geolog: require('./lib/geolog')(db)
    });

    console.log('Listening on port 8081');
    return app.listen(8081);
}))();
