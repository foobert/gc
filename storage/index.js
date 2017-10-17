#!/usr/bin/env node

const MongoClient = require('mongodb').MongoClient;
const access0 = require('./lib/access');
const rest = require('./lib/rest');

const main = async function() {
    try {
        const db = await MongoClient.connect('mongodb://localhost/gc');
        const access = access0(db.collection('auth'));
        const token = await access.init();
        console.log(`Token: ${token}`);

        const app = rest({
            access,
            geocache: require('./lib/geocache')(db.collection('geocaches')),
            geolog: require('./lib/geolog')(db),
        });

        console.log('Listening on port 8081');
        return app.listen(8081);
    } catch (err) {
        console.log(err);
    }
};
main();
