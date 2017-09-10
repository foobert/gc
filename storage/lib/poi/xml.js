/*
 * decaffeinate suggestions:
 * DS001: Remove Babel/TypeScript constructor workaround
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const stream = require('stream');
const xml2js = require('xml2js');

class XmlStream extends stream.Transform {
    constructor(pre, post, mapper) {
        {
          // Hack: trick Babel/TypeScript into allowing this before super.
          if (false) { super(); }
          let thisFn = (() => { this; }).toString();
          let thisName = thisFn.slice(thisFn.indexOf('{') + 1, thisFn.indexOf(';')).trim();
          eval(`${thisName} = this;`);
        }
        this.pre = pre;
        this.post = post;
        this.mapper = mapper;
        super({objectMode: true});
        this.builder = new xml2js.Builder({
            headless: true,
            renderOpts: { pretty: false
        }
        });
        this.push(this.pre);
    }

    _transform(obj, encoding, cb) {
        return cb(null, this.builder.buildObject(this.mapper(obj)));
    }

    _flush(cb) {
        this.push(this.post);
        return cb();
    }
}

module.exports = {
    transform(pre, post, mapper) {
        return new XmlStream(pre, post, mapper);
    }
};
