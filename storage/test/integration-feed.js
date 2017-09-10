/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const {expect} = require('chai');
const Promise = require('bluebird');
const request = require('superagent-as-promised');

const geocacheService = require('../lib/geocache');

describe('REST routes for feed', function() {
    this.timeout(15000);

    let db = null;
    let url = null;

    const setupTestData = Promise.coroutine(function*(geocaches) {
        geocaches = JSON.parse(JSON.stringify(geocaches));
        const g = geocacheService(db);
        yield g.deleteAll();
        for (let geocache of Array.from(geocaches)) {
            yield g.upsert(geocache);
        }
        return yield g.forceRefresh();
    });

    const gc = function(id, options) {
        const defaults = {
            Code: `GC${id}`,
            Name: 'geocache name',
            Latitude: 10,
            Longitude: 20,
            Terrain: 1,
            Difficulty: 1,
            Archived: false,
            Available: true,
            CacheType: { GeocacheTypeId: 2
        },
            ContainerType: { ContainerTypeName: 'Micro'
        },
            UTCPlaceDate: `/Date(${new Date().getTime()}-0000)/`,
            EncodedHints: 'some hints'
        };
        var merge = function(a, b) {
            if (b == null) { return a; }
            for (let k in b) {
                const v = b[k];
                if (typeof v === 'object') {
                    if (a[k] == null) { a[k] = {}; }
                    merge(a[k], v);
                } else {
                    a[k] = v;
                }
            }
            return a;
        };

        return merge(defaults, options);
    };

    before(Promise.coroutine(function*() {
        url = `http://${process.env.APP_PORT_8081_TCP_ADDR}:${process.env.APP_PORT_8081_TCP_PORT}`;
        db = require('../lib/db')({
            host: process.env.DB_PORT_5432_TCP_ADDR != null ? process.env.DB_PORT_5432_TCP_ADDR : 'localhost',
            user: process.env.DB_USER != null ? process.env.DB_USER : 'postgres',
            password: process.env.DB_PASSWORD,
            database: process.env.DB != null ? process.env.DB : 'gc'
        });

        let tries = 10;
        let appRunning = false;
        while (tries-- > 0) {
            try {
                const response = yield request.get(url);
                if (response.status === 200) {
                    console.log(`found app at ${url}`);
                    appRunning = true;
                    break;
                }
                yield Promise.delay(1000);
            } catch (err) {
                yield Promise.delay(1000);
            }
        }

        if (!appRunning) {
            throw new Error(`App is not running at ${url}`);
        }
    })
    );

    beforeEach(Promise.coroutine(function*() {
        return yield setupTestData([]);}));


    return describe('feed', function() {
        it('should send content type application/atom+xml', Promise.coroutine(function*() {
            const response = yield request
                .get(`${url}/feed`)
                .set('Accept', 'application/atom+xml');

            return expect(response.type).to.equal('application/atom+xml');
        })
        );

        it('should be a valid atom document', Promise.coroutine(function*() {
            const response = yield request
                .get(`${url}/feed`)
                .set('Accept', 'application/atom+xml');
            return console.log(response.text);
        })
        );

        return it('should have a valid atom header', Promise.coroutine(function*() {
            yield setupTestData([
                gc('100'),
                gc('101')
            ]);
            const response = yield request
                .get(`${url}/feed`)
                .set('Accept', 'application/atom+xml');
            return console.log(response.body);
        })
        );
    });
});


