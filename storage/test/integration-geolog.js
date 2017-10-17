/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const {expect} = require('chai');
const request = require('superagent');
const MongoClient = require('mongodb').MongoClient;

const access = require('../lib/access');
const geologService = require('../lib/geolog');

describe('REST routes for logs', function() {
    this.timeout(15000);

    let db = null;
    let token = null;
    let url = null;

    const setupTestData = async function(geologs) {
        geologs = JSON.parse(JSON.stringify(geologs));
        const client = await MongoClient.connect('mongodb://localhost/gc');
        const g = geologService(client);
        await g.deleteAll();
        for (let geolog of geologs) {
            await g.upsert(geolog);
        }
    };

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

    before(async function() {
        url = 'http://localhost:8081';
        const client = await MongoClient.connect('mongodb://localhost/gc');
        const a = access(client.collection('auth'));
        token = await a.getToken();

        let tries = 10;
        let appRunning = false;
        while (tries-- > 0) {
            try {
                const response = await request.get(url);
                if (response.status === 200) {
                    console.log(`found app at ${url}`);
                    appRunning = true;
                    break;
                }
                //yield Promise.delay(1000);
            } catch (err) {
                //yield Promise.delay(1000);
            }
        }

        if (!appRunning) {
            throw new Error(`App is not running at ${url}`);
        }
    });

    beforeEach(async function() {
        await setupTestData([]);
    });

    describe('GET /logs/latest', function() {
        it('should get the latest log for the given username', async function() {
            const a = gl('100', {VisitDate: '/Date(1431889200000-0700)/'});
            const b = gl('101', {VisitDate: '/Date(1451889200000-0700)/'});
            const c = gl('102', {VisitDate: '/Date(1441889200000-0700)/'});

            await setupTestData([a, b, c]);

            const response = await request.get(`${url}/logs/latest`)
                .query({username: 'Foobar'})
                .set('Accept', 'application/json');
            expect(response.status).to.equal(200);
            expect(response.text).to.equal('GL101');
        });

        it('should accept the username in any case', async function() {
            const a = gl('100', {VisitDate: '/Date(1431889200000-0700)/'});
            await setupTestData([a]);

            const response = await request.get(`${url}/logs/latest`)
                .query({username: 'foOBar'})
                .set('Accept', 'application/json');
            expect(response.text).to.equal('GL100');
        });

        it('should return the latest if no username is given', async function() {
            const a = gl('100', {VisitDate: '/Date(1431889200000-0700)/'});
            await setupTestData([a]);

            const response = await request.get(`${url}/logs/latest`)
                .set('Accept', 'application/json');
            expect(response.status).to.equal(200);
            expect(response.text).to.equal('GL100');
        });

        it('should return 404 if no logs can be found', async function() {
            try {
                await request.get(`${url}/logs/latest`)
                    .query({username: 'nobody'})
                    .set('Accept', 'application/json');
                expect(true, 'expected an error').to.be.false;
            } catch (err) {
                expect(err.status).to.equal(404);
            }
        });
    });

    describe('POST /log', function() {
        it('should create a new log', async function() {
            let result;
            const a = gl('100');
            await request
                .post(`${url}/log`)
                .set('Content-Type', 'application/json')
                .set('X-Token', token)
                .send(a);


            const client = await MongoClient.connect('mongodb://localhost/gc');
            const db = client.collection('geologs');
            const count = await db.count({});

            expect(count).to.equal(1);
            //expect(result.rows[0].data).to.deep.equal(a);
        });

        it('should return 201', async function() {
            const a = gl('100');
            const response = await request
                .post(`${url}/log`)
                .set('Content-Type', 'application/json')
                .set('X-Token', token)
                .send(a);
            expect(response.status).to.equal(201);
        });
    });
});
