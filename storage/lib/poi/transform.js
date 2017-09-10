/*
 * decaffeinate suggestions:
 * DS001: Remove Babel/TypeScript constructor workaround
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const stream = require('stream');

class Mapper extends stream.Transform {
    constructor(mapper) {
        {
          // Hack: trick Babel/TypeScript into allowing this before super.
          if (false) { super(); }
          let thisFn = (() => { this; }).toString();
          let thisName = thisFn.slice(thisFn.indexOf('{') + 1, thisFn.indexOf(';')).trim();
          eval(`${thisName} = this;`);
        }
        this.mapper = mapper;
        super({objectMode: true});
    }

    _transform(obj, encoding, cb) {
        return cb(null, this.mapper(obj));
    }

    _flush(cb) {
        return cb();
    }
}

module.exports = mapper => new Mapper(mapper);
