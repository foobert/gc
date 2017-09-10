/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const {expect} = require('chai');
const Promise = require('bluebird');
const request = require('superagent-as-promised');

const access = require('../lib/access');
const geologService = require('../lib/geolog');

describe('REST routes for logs', function() {
    this.timeout(15000);

    let db = null;
    let token = null;
    let url = null;

    const setupTestData = Promise.coroutine(function*(geologs) {
        geologs = JSON.parse(JSON.stringify(geologs));
        const g = geologService(db);
        yield g.deleteAll();
        return yield* (function*() {
            const result = [];
            for (let geolog of Array.from(geologs)) {
                result.push(yield g.upsert(geolog));
            }
            return result;
        }).call(this);
    });

    const gl = function(id, options) {
        const defaults = {
            Code: `GL${id}`,
            CacheCode: 'GC12345',
            Finder: { UserName: 'Foobar'
        },
            LogType: { WptLogTypeId: 2
        },
            UTCCreateDate: '/Date(1431813667662)/',
            VisitDate: '/Date(1431889200000-0700)/'
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

        const a = access(db);
        token = yield a.getToken();

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

    describe('GET /logs/latest', function() {
        it('should get the latest log for the given username', Promise.coroutine(function*() {
            const a = gl('100', {VisitDate: '/Date(1431889200000-0700)/'});
            const b = gl('101', {VisitDate: '/Date(1421889200000-0700)/'});

            yield setupTestData([a, b]);

            const response = yield request.get(`${url}/logs/latest`)
                .query({username: 'Foobar'})
                .set('Accept', 'application/json');
            expect(response.status).to.equal(200);
            return expect(response.text).to.equal('GL100');
        })
        );

        it('should accept the username in any case', Promise.coroutine(function*() {
            const a = gl('100', {VisitDate: '/Date(1431889200000-0700)/'});
            yield setupTestData([a]);

            const response = yield request.get(`${url}/logs/latest`)
                .query({username: 'foOBar'})
                .set('Accept', 'application/json');
            return expect(response.text).to.equal('GL100');
        })
        );

        it('should return the latest if no username is given', Promise.coroutine(function*() {
            const a = gl('100', {VisitDate: '/Date(1431889200000-0700)/'});
            yield setupTestData([a]);

            const response = yield request.get(`${url}/logs/latest`)
                .set('Accept', 'application/json');
            expect(response.status).to.equal(200);
            return expect(response.text).to.equal('GL100');
        })
        );

        return it('should return 404 if no logs can be found', Promise.coroutine(function*() {
            try {
                yield request.get(`${url}/logs/latest`)
                    .query({username: 'nobody'})
                    .set('Accept', 'application/json');
                return expect(true, 'expected an error').to.be.false;
            } catch (err) {
                return expect(err.status).to.equal(404);
            }
        })
        );
    });

    return describe('POST /log', function() {
        it('should create a new log', Promise.coroutine(function*() {
            let result;
            const a = gl('100');
            yield request
                .post(`${url}/log`)
                .set('Content-Type', 'application/json')
                .set('X-Token', token)
                .send(a);

            const [client, done] = Array.from(yield db.connect());
            try {
                result = yield client.queryAsync('SELECT data FROM logs WHERE lower(id) = \'gl100\'');
            } finally {
                done();
            }

            expect(result.rowCount).to.equal(1);
            return expect(result.rows[0].data).to.deep.equal(a);
        })
        );

        return it('should return 201', Promise.coroutine(function*() {
            const a = gl('100');
            const response = yield request
                .post(`${url}/log`)
                .set('Content-Type', 'application/json')
                .set('X-Token', token)
                .send(a);
            return expect(response.status).to.equal(201);
        })
        );
    });
});
