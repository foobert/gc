/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const stream = require('stream');

class QueryStream extends stream.Readable {
    constructor(query, map, done) {
        super({objectMode: true});

        query.on('row', row => {
            return this.push(map(row));
        });
        query.on('end', result => {
            this.push(null);
            return done();
        });
        query.on('error', err => {
            this.push(null);
            return done(err);
        });
    }

    _read() {}
}

module.exports = QueryStream;
