/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const debug = require('debug')('gc:geologs');
const upsert = require('../db/upsert');
const Promise = require('bluebird');

module.exports = db =>
    ({
        upsert(data) {
            debug(`upsert ${(data.Code != null ? data.Code.toLowerCase() : undefined)}`);
            return upsert(db, 'logs', data);
        },

        latest: Promise.coroutine(function*(username) {
            debug(`latest ${username}`);
            const [client, done] = Array.from(yield db.connect());
            try {
                let sql = db.select()
                    .from('logsRel')
                    .field('id')
                    .order('visitdate', false)
                    .limit(1);
                if (username != null) { sql = sql.where('lower(username) = ?', username.trim().toLowerCase()); }
                sql = sql.toString();

                const result = yield client.queryAsync(sql);
                if (result.rowCount === 0) {
                    return null;
                } else {
                    return result.rows[0].id.trim().toUpperCase();
                }
            } finally {
                done();
            }
        }),

        deleteAll: Promise.coroutine(function*() {
            debug('delete all');
            const [client, done] = Array.from(yield db.connect());
            try {
                const sql = db.delete()
                    .from('logs')
                    .toString();
                return yield client.queryAsync(sql);
            } finally {
                done();
            }
        })
    })
;
