/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Promise = require('bluebird');

const upsert = Promise.coroutine(function*(db, client, table, data) {
    const id = data.Code != null ? data.Code.toLowerCase() : undefined;
    const updated = data.meta != null ? data.meta.updated : undefined;
    delete data.meta;

    if ((id == null)) { throw new Error("Missing data attribute 'Code'"); }

    try {
        yield client.queryAsync('BEGIN');

        let sql = db.select()
            .field('id')
            .from(table)
            .where('id = ?', id)
            .toString();
        let result = yield client.queryAsync(sql);
        sql = result.rowCount === 0 ?
            db.insert({numberedParameters: true})
                .into(table)
                .set('id', id)
                .set('updated', updated || 'now', {dontQuote: (updated == null)})
                .set('data', JSON.stringify(data))
                .toParam()
        :
            db.update({numberedParameters: true})
                .table(table)
                .set('updated', updated || 'now', {dontQuote: (updated == null)})
                .set('data', JSON.stringify(data))
                .where('id = ?', id)
                .toParam();
        result = yield client.queryAsync(sql);
        if (result.rowCount === 0) { throw new Error(`Insert/update had no effect: ${sql}`); }
        return yield client.queryAsync('COMMIT');
    } catch (err) {
        yield client.queryAsync('ROLLBACK');
        throw err;
    }
});

module.exports = Promise.coroutine(function*(db, table, data) {
    const [client, done] = Array.from(yield db.connect());
    try {
        return yield upsert(db, client, table, data);
    } finally {
        done();
    }
});
