module.exports = function(app, geolog) {
    app.post('/log', async function(req, res, next) {
        await geolog.upsert(req.body);
        res.status(201);
        res.send('');
    });

    app.get('/logs/latest', async function(req, res, next) {
        const id = await geolog.latest(req.query.username);
        if (id != null) {
            res.status(200);
            res.send(id);
        } else {
            res.status(404);
            res.send('No logs');
        }
    });
}
