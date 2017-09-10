/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const fs = require('fs');
const moment = require('moment');
const Promise = require('bluebird');
const {expect} = require('chai');

describe('geocache', function() {
    let streamToArray;
    this.timeout(5000);

    let db = null;
    let geocaches = null;

    let GC1BAZ8 = null;
    let GC38XPR = null;

    before(Promise.coroutine(function*() {
        db = require('../lib/db')({
            host: process.env.DB_PORT_5432_TCP_ADDR != null ? process.env.DB_PORT_5432_TCP_ADDR : 'localhost',
            user: process.env.DB_USER != null ? process.env.DB_USER : 'postgres',
            password: process.env.DB_PASSWORD,
            database: process.env.DB != null ? process.env.DB : 'gc'
        });
        yield db.up();
        geocaches = require('../lib/geocache')(db);

        GC1BAZ8 = JSON.parse(fs.readFileSync(`${__dirname}/data/GC1BAZ8`, 'utf8'));
        return GC38XPR = JSON.parse(fs.readFileSync(`${__dirname}/data/GC38XPR`, 'utf8'));
    })
    );

    beforeEach(Promise.coroutine(function*() {
        const [client, done] = Array.from(yield db.connect());
        yield client.queryAsync('DELETE FROM geocaches');
        return done();
    })
    );

    describe('get', function() {
        it('should return data from a previous upsert', Promise.coroutine(function*() {
            yield geocaches.upsert(GC1BAZ8);
            const gc = yield geocaches.get('GC1BAZ8');
            // TODO hrm
            delete gc.meta;
            return expect(gc).to.deep.equal(GC1BAZ8);
        })
        );

        it('should accept the id in mixed casing', Promise.coroutine(function*() {
            yield geocaches.upsert(GC1BAZ8);
            const gc = yield geocaches.get('gc1BAz8');
            return expect(gc).to.exist;
        })
        );

        return it('should return null if no geocache exists', Promise.coroutine(function*() {
            const gc = yield geocaches.get('non-existing-id');
            return expect(gc).to.not.exist;
        })
        );
    });

    describe('upsert', function() {
        it('should overwrite a previous geocache', Promise.coroutine(function*() {
            const copy = JSON.parse(JSON.stringify(GC1BAZ8));
            copy.Name = 'new name';

            yield geocaches.upsert(GC1BAZ8);
            yield geocaches.upsert(copy);
            const gc = yield geocaches.get('GC1BAZ8');

            return expect(gc.Name).to.equal('new name');
        })
        );

        return it('should update the updated field', Promise.coroutine(function*() {
            yield geocaches.upsert(GC1BAZ8);
            const oldGc = yield geocaches.get('GC1BAZ8');

            // Make sure we actually get some delay in the updated value ;-)
            yield Promise.delay(20);

            yield geocaches.upsert(GC1BAZ8);
            const newGc = yield geocaches.get('GC1BAZ8');

            return expect(newGc.meta.updated.getTime()).to.be.greaterThan(oldGc.meta.updated.getTime());
        })
        );
    });

    describe('touch', function() {
        let oldGc = null;
        beforeEach(Promise.coroutine(function*() {
            yield geocaches.upsert(GC1BAZ8);
            return oldGc = yield geocaches.get('GC1BAZ8');
        })
        );

        it('should update the updated field', Promise.coroutine(function*() {
            // Make sure we actually get some delay in the updated value ;-)
            yield Promise.delay(20);

            yield geocaches.touch('GC1BAZ8');
            const newGc = yield geocaches.get('GC1BAZ8');

            return expect(newGc.meta.updated.getTime()).to.be.greaterThan(oldGc.meta.updated.getTime());
        })
        );

        it('should update the updated field to a given date', Promise.coroutine(function*() {
            // Make sure we actually get some delay in the updated value ;-)
            yield Promise.delay(20);

            const updated = new Date('2015-01-01 06:00Z');
            yield geocaches.touch('GC1BAZ8', updated);
            const newGc = yield geocaches.get('GC1BAZ8');

            return expect(newGc.meta.updated.getTime()).to.be.equal(updated.getTime());
        })
        );

        return it('should do nothing if the geocache does not exist', Promise.coroutine(function*() {
            return yield geocaches.touch('non-existing-id');
        })
        );
    });

    describe('delete', function() {
        it('should delete a geocache', Promise.coroutine(function*() {
            yield geocaches.upsert(GC1BAZ8);
            yield geocaches.delete('GC1BAZ8');
            const gc = yield geocaches.get('GC1BAZ8');
            return expect(gc).to.not.exist;
        })
        );

        it('should accept mixed case ids', Promise.coroutine(function*() {
            yield geocaches.upsert(GC1BAZ8);
            yield geocaches.delete('gc1BAz8');
            const gc = yield geocaches.get('GC1BAZ8');
            return expect(gc).to.not.exist;
        })
        );

        return it('should do nothing if the geoache does not exist', Promise.coroutine(function*() {
            return yield geocaches.delete('non-existing-id');
        })
        );
    });

    describe('deleteAll', function() {
        it('should delete all geocaches', Promise.coroutine(function*() {
            yield geocaches.upsert(GC1BAZ8);
            yield geocaches.upsert(GC38XPR);
            yield geocaches.deleteAll();
            expect(yield geocaches.get('GC1BAZ8')).to.not.exist;
            return expect(yield geocaches.get('GC38XPR')).to.not.exist;
        })
        );

        return it('should do nothing if no geocaches exist', Promise.coroutine(function*() {
            return yield geocaches.deleteAll();
        })
        );
    });

    describe('getStream', function() {
        it('should sort by default ascending', Promise.coroutine(function*() {
            yield geocaches.upsert(GC1BAZ8);
            yield geocaches.upsert(GC38XPR);
            yield geocaches.forceRefresh();
            const stream = yield geocaches.getStream({
                orderBy: 'UTCPlaceDate',
                stale: '1'
            }
            , true);

            const arr = yield streamToArray(stream);
            const codes = arr.map(gc => gc.Code);
            return expect(codes).to.deep.equal(['GC1BAZ8', 'GC38XPR']);}));

        it('should sort by orderBy ascending', Promise.coroutine(function*() {
            yield geocaches.upsert(GC1BAZ8);
            yield geocaches.upsert(GC38XPR);
            yield geocaches.forceRefresh();
            const stream = yield geocaches.getStream({
                orderBy: 'UTCPlaceDate',
                order: 'asc',
                stale: '1'
            }
            , true);

            const arr = yield streamToArray(stream);
            const codes = arr.map(gc => gc.Code);
            return expect(codes).to.deep.equal(['GC1BAZ8', 'GC38XPR']);}));

        it('should sort by orderBy descending', Promise.coroutine(function*() {
            yield geocaches.upsert(GC1BAZ8);
            yield geocaches.upsert(GC38XPR);
            yield geocaches.forceRefresh();
            const stream = yield geocaches.getStream({
                orderBy: 'UTCPlaceDate',
                order: 'desc',
                stale: '1'
            }
            , true);

            const arr = yield streamToArray(stream);
            const codes = arr.map(gc => gc.Code);
            return expect(codes).to.deep.equal(['GC38XPR', 'GC1BAZ8']);}));

        return it('should filter based on last update date', Promise.coroutine(function*() {
            const gc1 = JSON.parse(JSON.stringify(GC1BAZ8));
            const gc2 = JSON.parse(JSON.stringify(GC38XPR));
            gc1.meta = {updated: moment().subtract(10, 'days').format()};
            gc2.meta = {updated: moment().subtract(1, 'day').format()};
            yield geocaches.upsert(gc1);
            yield geocaches.upsert(gc2);
            yield geocaches.forceRefresh();

            const stream = yield geocaches.getStream({
                orderBy: 'updated',
                order: 'desc',
                stale: '> 5 days'
            }
            , true);

            const arr = yield streamToArray(stream);
            const codes = arr.map(gc => gc.Code);
            return expect(codes).to.deep.equal([gc1.Code]);}));
});

    return streamToArray = function(stream) {
        const result = [];
        return new Promise(function(resolve, reject) {
            stream.on('data', x => result.push(x));
            stream.on('end', () => resolve(result));
            return stream.on('error', err => reject(err));
        });
    };
});
