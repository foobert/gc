/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Promise = require('bluebird');

module.exports = f =>
    Promise.coroutine(function*(req, res, next) {
        try {
            return yield* f(req, res, next);
        } catch (err) {
            return next(err);
        }
    })
;
