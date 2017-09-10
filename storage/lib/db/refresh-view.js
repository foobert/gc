/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const _ = require('lodash');
const Promise = require('bluebird');

module.exports = {
    refresh: Promise.coroutine(function*(db, view, debug) {
        if (debug != null) { debug('refresh view'); }
        const [client, done] = Array.from(yield db.connect());
        try {
            // SQL INJECTION on `view` possible?
            yield client.queryAsync(`REFRESH MATERIALIZED VIEW ${view}`);
            if (debug != null) { return debug('refresh view complete'); }
        } finally {
            done();
        }
    }),

    debounce(db, view, timeout, debug) {
        return _.debounce((() => this.refresh(db, view, debug)), timeout);
    }
};
