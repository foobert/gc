async = require '../rest-async'

module.exports = (app, geolog) ->
    app.post '/log', async (req, res, next) ->
        yield geolog.upsert req.body
        res.status 201
        res.send ''

    app.get '/logs/latest', async (req, res, next) ->
        id = yield geolog.latest req.query.username
        if id?
            res.status(200).send id
        else
            res.status(404).send 'No logs'
