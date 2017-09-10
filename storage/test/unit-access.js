/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const {expect} = require('chai');
const uuid = require('uuid');
const Promise = require('bluebird');
Promise.longStackTraces();

describe('access', function() {
    this.timeout(5000);

    let access = null;

    before(Promise.coroutine(function*() {
        const db = require('../lib/db')({
            host: process.env.DB_PORT_5432_TCP_ADDR != null ? process.env.DB_PORT_5432_TCP_ADDR : 'localhost',
            user: process.env.DB_USER != null ? process.env.DB_USER : 'postgres',
            password: process.env.DB_PASSWORD,
            database: process.env.DB != null ? process.env.DB : 'gc'
        });
        yield db.up();
        return access = require('../lib/access')(db);
    })
    );

    describe('init', () =>
        it('should return a token', Promise.coroutine(function*() {
            const token = yield access.init();
            return expect(token).to.exist;
        })
        )
    );

    return describe('initialized', function() {
        before(Promise.coroutine(function*() {
            return yield access.init();
        })
        );

        describe('getToken', () =>
            it('should return a token', Promise.coroutine(function*() {
                const token = yield access.getToken();
                return expect(token).to.exist;
            })
            )
        );

        describe('addToken', () =>
            it('should return a valid token', Promise.coroutine(function*() {
                const token = yield access.addToken();
                return expect(yield access.check(token)).to.be.true;
            })
            )
        );

        return describe('check', function() {
            it('should return true for a valid token', Promise.coroutine(function*() {
                const token = yield access.getToken();
                const result = yield access.check(token);
                return expect(result).to.be.true;
            })
            );

            it('should return false for an invalid token', Promise.coroutine(function*() {
                const result = yield access.check(uuid());
                return expect(result).to.be.false;
            })
            );

            return it('should return false for a null token', Promise.coroutine(function*() {
                const result = yield access.check(null);
                return expect(result).to.be.false;
            })
            );
        });
    });
});
