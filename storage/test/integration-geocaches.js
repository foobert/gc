/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const {expect} = require('chai');
const request = require('superagent');
const MongoClient = require('mongodb').MongoClient;

const access = require('../lib/access');
const geocacheService = require('../lib/geocache');

describe('REST routes for geocaches', function() {
    this.timeout(5000);

    let db = null;
    let token = null;
    let url = null;

    const setupTestData = async function(gcs) {
        const client = await MongoClient.connect('mongodb://localhost/gc');
        const db = client.collection('geocaches');
        await db.deleteMany({});

        if (gcs.length > 0) {
            const docs = gcs.map((gc) => {
                const updated = (gc.meta && gc.meta.updated) ? gc.meta.updated : new Date();
                return {
                    _id: gc.Code.toLowerCase(),
                    coord: {type: 'Point', coordinates: [gc.Longitude, gc.Latitude]},
                    updated: new Date(updated),
                    data: gc,
                    placed: new Date(parseInt(gc.UTCPlaceDate.substr(6))),
                };
            });
            await db.insertMany(docs);
        }
    };

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

    before(async function() {
        url = 'http://localhost:8081';
        //token = '29273fd2-ad07-4269-8383-7543b41f1dac';
        const client = await MongoClient.connect('mongodb://localhost/gc');
        token = await access(client.collection('auth')).getToken();

        let tries = 5;
        let appRunning = false;
        while (tries-- > 0) {
            try {
                const response = await request.get(url);
                if (response.status === 200) {
                    appRunning = true;
                    break;
                }
                //await Promise.delay(1000);
            } catch (err) {
                //await Promise.delay(1000);
            }
        }

        if (!appRunning) {
            throw new Error(`App is not running at ${url}`);
        }
    });

    beforeEach(async function() {
        await setupTestData([]);
    });

    describe('/gcs', function() {
        it('should return a list of GC numbers on GET', async function() {
            await setupTestData([
                gc('100'),
                gc('101')
            ]);
            const response = await request
                .get(`${url}/gcs`)
                .set('Accept', 'application/json');
            expect(response.type).to.equal('application/json');
            expect(response.body.length).to.equal(2);
            expect(response.body).to.include.members(['GC100', 'GC101']);
        });

        it('should filter by age using "maxAge"', async function() {
            await setupTestData([
                gc('100', {UTCPlaceDate: `/Date(${new Date().getTime()}-0000)/`}),
                gc('101', {UTCPlaceDate: '/Date(00946684800-0000)/'})
            ]);
            const response = await request
                .get(`${url}/gcs`)
                .query({maxAge: 1})
                .set('Accept', 'application/json');
            expect(response.type).to.equal('application/json');
            expect(response.body.length).to.equal(1);
            expect(response.body).to.include.members(['GC100']);
        });

        it('should filter by coordinates using "bounds"', async function() {
            await setupTestData([
                gc('100', {
                    Latitude: 10,
                    Longitude: 10
                }
                ),
                gc('101', {
                    Latitude: 10,
                    Longitude: 11
                }
                ),
                gc('102', {
                    Latitude: 11,
                    Longitude: 10
                }
                ),
                gc('103', {
                    Latitude: 11,
                    Longitude: 11
                }
                )
            ]);
            const response = await request
                .get(`${url}/gcs`)
                .query({bounds: [9.5, 9.5, 10.5, 10.5]})
                .set('Accept', 'application/json');
            expect(response.type).to.equal('application/json');
            expect(response.body.length).to.equal(1);
            expect(response.body).to.include.members(['GC100']);
        });

        it('should filter by type id using "typeIds"', async function() {
            await setupTestData([
                gc('100', {CacheType: {GeocacheTypeId: 5}}),
                gc('101', {CacheType: {GeocacheTypeId: 6}}),
                gc('102', {CacheType: {GeocacheTypeId: 7}})
            ]);
            const response = await request
                .get(`${url}/gcs`)
                .query({typeIds: [5, 7]})
                .set('Accept', 'application/json');
            expect(response.type).to.equal('application/json');
            expect(response.body.length).to.equal(2);
            expect(response.body).to.include.members(['GC100', 'GC102']);
        });

        it('should filter disabled/archived geocaches using "excludeDisabled"', async function() {
            await setupTestData([
                gc('100', {
                    Archived: false,
                    Available: false
                }
                ),
                gc('101', {
                    Archived: false,
                    Available: true
                }
                ),
                gc('102', {
                    Archived: true,
                    Available: false
                }
                ),
                gc('103', {
                    Archived: true,
                    Available: true
                }
                )
            ]);
            const response = await request
                .get(`${url}/gcs`)
                .query({excludeDisabled: 1})
                .set('Accept', 'application/json');
            expect(response.type).to.equal('application/json');
            expect(response.body.length).to.equal(1);
            expect(response.body).to.include.members(['GC101']);
        });

        it('should return disabled/archived geocaches by default', async function() {
            await setupTestData([
                gc('100', {
                    Archived: false,
                    Available: false
                }
                ),
                gc('101', {
                    Archived: false,
                    Available: true
                }
                ),
                gc('102', {
                    Archived: true,
                    Available: false
                }
                ),
                gc('103', {
                    Archived: true,
                    Available: true
                }
                )
            ]);
            const response = await request
                .get(`${url}/gcs`)
                .set('Accept', 'application/json');
            expect(response.type).to.equal('application/json');
            expect(response.body.length).to.equal(4);
            expect(response.body).to.include.members(['GC100', 'GC101', 'GC102', 'GC103']);
        });


        it('should filter stale geocaches by default', async function() {
            await setupTestData([
                gc('100', {meta: {updated: new Date().toISOString()}}),
                gc('101', {meta: {updated: '2000-01-01 00:00:00Z'}})
            ]);
            const response = await request
                .get(`${url}/gcs`)
                .set('Accept', 'application/json');
            expect(response.type).to.equal('application/json');
            expect(response.body.length).to.equal(1);
            expect(response.body).to.include.members(['GC100']);
        });

        it('should return stale geocaches when "stale" is 1', async function() {
            await setupTestData([
                gc('100', {meta: {updated: new Date().toISOString()}}),
                gc('101', {meta: {updated: '2000-01-01 00:00:00Z'}})
            ]);
            const response = await request
                .get(`${url}/gcs`)
                .query({stale: 1})
                .set('Accept', 'application/json');
            expect(response.type).to.equal('application/json');
            expect(response.body.length).to.equal(2);
            expect(response.body).to.include.members(['GC100', 'GC101']);
        });
    });

    describe('/geocaches', function() {
        it('should return a list of geocaches on GET', async function() {
            const a = gc('100');
            const b = gc('101');
            await setupTestData([a, b]);
            const response = await request
                .get(`${url}/geocaches`)
                .set('Accept', 'application/json');

            expect(response.type).to.equal('application/json');
            expect(response.body.length).to.equal(2);
            expect(response.body.map(gc => gc.Code)).to.deep.equal(['GC100', 'GC101']);
        });

        [{
            name: 'Code',
            type: 'String'
        }
        , {
            name: 'Name',
            type: 'String'
        }
        , {
            name: 'Terrain',
            type: 'Number'
        }
        , {
            name: 'Difficulty',
            type: 'Number'
        }
        , {
            name: 'Archived',
            type: 'Boolean'
        }
        , {
            name: 'UTCPlaceDate',
            type: 'String'
        }
        ].forEach(({name, type}) => {
            it(`should include field ${name} of type ${type}`, async function() {
                const a = gc('100');
                await setupTestData([a]);
                const response = await request
                    .get(`${url}/geocaches`)
                    .set('Accept', 'application/json');

                const [result] = Array.from(response.body);
                expect(result[name]).to.exist;
                expect(result[name]).to.be.a(type);
            });
        });

        it('should include the update timestamp', async function() {
            const a = gc('100', {meta: {updated: new Date().toISOString()}});
            await setupTestData([a]);
            const response = await request
                .get(`${url}/geocaches`)
                .set('Accept', 'application/json');

            const [result] = Array.from(response.body);
            expect(result.meta.updated).to.equal(a.meta.updated);
        });

        it('should create new geocaches on POST', async function() {
            const a = gc('100', {meta: {updated: new Date().toISOString()}});

            const putResponse = await request
                .post(`${url}/geocache`)
                .set('Content-Type', 'application/json')
                .set('X-Token', token)
                .send(a);

            const getResponse = await request
                .get(`${url}/geocache/GC100`)
                .set('Accept', 'application/json');

            expect(putResponse.status).to.equal(201);
            expect(getResponse.status).to.equal(200);
        });

        it('should should reject POSTs without a valid API key', async function() {
            let err;
            const a = gc('100', {meta: {updated: new Date().toISOString()}});

            try {
                const putResponse = await request
                    .post(`${url}/geocache`)
                    .set('Content-Type', 'application/json')
                    .set('X-Token', 'invalid')
                    .send(a);
            } catch (error) { err = error; }
                // expected

            expect(err.status).to.equal(403);

            const getResponse = await request
                .get(`${url}/geocaches`)
                .set('Accept', 'application/json');

            expect(getResponse.body).to.deep.equal([]);
        });

        it('should should reject POSTs with a missing API key', async function() {
            let err;
            const a = gc('100', {meta: {updated: new Date().toISOString()}});

            try {
                const putResponse = await request
                    .post(`${url}/geocache`)
                    .set('Content-Type', 'application/json')
                    .send(a);
            } catch (error) { err = error; }
                // expected

            expect(err.status).to.equal(403);

            const getResponse = await request
                .get(`${url}/geocaches`)
                .set('Accept', 'application/json');

            expect(getResponse.body).to.deep.equal([]);
        });
    });
});
