/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const async = require('../rest-async');

module.exports = function(app, geolog) {
    app.post('/log', async(function*(req, res, next) {
        yield geolog.upsert(req.body);
        res.status(201);
        return res.send('');
    })
    );

    return app.get('/logs/latest', async(function*(req, res, next) {
        const id = yield geolog.latest(req.query.username);
        if (id != null) {
            return res.status(200).send(id);
        } else {
            return res.status(404).send('No logs');
        }
    })
    );
};
