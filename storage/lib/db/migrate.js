/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const debug = require('debug')('gc:migrate');
const pg = require('pg');
const Promise = require('bluebird');
Promise.promisifyAll(pg);

module.exports = function() {
    let expectedVersion = 0;

    const ensureDb = Promise.coroutine(function*(db) {
        const [client, done] = Array.from(yield db.connect('postgres'));
        try {
            const result = yield client.queryAsync('SELECT 0 FROM pg_database WHERE datname = $1', [db.database]);
            if (result.rowCount !== 1) {
                debug(`creating database ${db.database}`);
                // TODO possible sql injection?
                return yield client.queryAsync(`CREATE DATABASE ${db.database}`);
            }
        } finally {
            done();
        }
    });

    const getCurrentVersion = Promise.coroutine(function*(client) {
        let result = yield client.queryAsync('SELECT 0 FROM pg_tables WHERE schemaname = \'public\' AND tablename = \'_schema\'');
        if (result.rowCount === 0) {
            yield client.queryAsync('CREATE TABLE _schema (version integer)');
        }

        result = yield client.queryAsync('SELECT version FROM _schema');
        if (result.rowCount !== 0) {
            return result.rows[0].version;
        } else {
            yield client.queryAsync('INSERT INTO _schema VALUES(0)');
            return 0;
        }
    });

    return {
        up: Promise.coroutine(function*(db, statements) {
            let err;
            yield ensureDb(db);
            expectedVersion += 1;
            const [client, done] = Array.from(yield db.connect());
            try {
                const currentVersion = yield getCurrentVersion(client);
                if (currentVersion < expectedVersion) {
                    debug(`migrating from ${currentVersion} to ${expectedVersion}`);
                    yield client.queryAsync('BEGIN');
                    for (let statement of Array.from(statements)) {
                        debug(statement);
                        yield client.queryAsync(statement);
                    }
                    yield client.queryAsync('UPDATE _schema SET version = $1', [expectedVersion]);
                    return yield client.queryAsync('COMMIT');
                }
            } catch (error) {
                err = error;
                if (client != null) { yield client.queryAsync('ROLLBACK'); }
                throw err;
            }
            finally {
                done(err);
            }
        })
    };
};
