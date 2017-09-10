/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const uuid = require('uuid');
const Promise = require('bluebird');

module.exports = db =>
    ({
        init: Promise.coroutine(function*() {
            return (yield this.getToken()) || (yield this.addToken());
        }),

        check: Promise.coroutine(function*(token) {
            if ((token == null)) { return false; }

            const [client, done] = Array.from(yield db.connect());
            try {
                const sql = db.select()
                    .from('tokens')
                    .field('id')
                    .where('id = ?', token)
                    .toString();

                const result = yield client.queryAsync(sql);
                return result.rowCount === 1;
            } catch (err) {
                return false;
            }
            finally {
                done();
            }
        }),

        addToken: Promise.coroutine(function*() {
            const token = uuid.v4();
            const [client, done] = Array.from(yield db.connect());
            try {
                const sql = db.insert()
                    .into('tokens')
                    .set('id', token)
                    .toString();
                const result = yield client.queryAsync(sql);
                return token;
            } finally {
                done();
            }
        }),

        getToken: Promise.coroutine(function*() {
            const [client, done] = Array.from(yield db.connect());
            try {
                const sql = db.select()
                    .from('tokens')
                    .field('id')
                    .limit(1)
                    .toString();
                const result = yield client.queryAsync(sql);
                if (result.rowCount === 0) {
                    return null;
                } else {
                    return result.rows[0].id;
                }
            } finally {
                done();
            }
        })
    })
;
