/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const fs = require('fs');
const Promise = require('bluebird');
const {expect} = require('chai');

describe('geolog', function() {
    this.timeout(5000);

    let db = null;
    let geologs = null;

    let GL00001 = null;
    let GL00002 = null;

    before(Promise.coroutine(function*() {
        db = require('../lib/db')({
            host: process.env.DB_PORT_5432_TCP_ADDR != null ? process.env.DB_PORT_5432_TCP_ADDR : 'localhost',
            user: process.env.DB_USER != null ? process.env.DB_USER : 'postgres',
            password: process.env.DB_PASSWORD,
            database: process.env.DB != null ? process.env.DB : 'gc'
        });
        yield db.up();
        geologs = require('../lib/geolog')(db);

        GL00001 = JSON.parse(fs.readFileSync(`${__dirname}/data/GL00001`, 'utf8'));
        return GL00002 = JSON.parse(fs.readFileSync(`${__dirname}/data/GL00002`, 'utf8'));
    })
    );

    beforeEach(Promise.coroutine(function*() {
        const [client, done] = Array.from(yield db.connect());
        yield client.queryAsync('DELETE FROM logs');
        return done();
    })
    );

    const get = Promise.coroutine(function*(id) {
        const [client, done] = Array.from(yield db.connect());
        try {
            const result = yield client.queryAsync('SELECT data FROM logs WHERE lower(id) = lower($1)', [id]);
            return (result.rows[0] != null ? result.rows[0].data : undefined);
        } finally {
            done();
        }
    });

    describe('upsert', function() {
        it('should insert a new geolog', Promise.coroutine(function*() {
            yield geologs.upsert(GL00001);
            const gl = yield get('GL00001');
            return expect(gl).to.deep.equal(GL00001);
        })
        );

        return it('should update an existing geolog', Promise.coroutine(function*() {
            const copy = JSON.parse(JSON.stringify(GL00001));
            copy.LogText = 'TYFTC';
            yield geologs.upsert(GL00001);
            yield geologs.upsert(copy);
            const gl = yield get('GL00001');
            return expect(gl.LogText).to.equal('TYFTC');
        })
        );
    });

    describe('latest', function() {
        it('should return the latest log for a given username', Promise.coroutine(function*() {
            yield geologs.upsert(GL00001);
            yield geologs.upsert(GL00002);
            const latest = yield geologs.latest('Foobar');
            return expect(latest).to.equal('GL00001');
        })
        );

        return it('should return null if no geologs exist', Promise.coroutine(function*() {
            const latest = yield geologs.latest('nobody');
            return expect(latest).to.not.exist;
        })
        );
    });

    return describe('deleteAll', () =>
        it('should delete all logs', Promise.coroutine(function*() {
            yield geologs.upsert(GL00001);
            yield geologs.upsert(GL00002);
            yield geologs.deleteAll();
            const [client, done] = Array.from(yield db.connect());
            try {
                const result = yield client.queryAsync('SELECT count(*) FROM logs');
                return expect(result.rows[0].count).to.equal('0');
            } finally {
                done();
            }
        })
        )
    );
});

