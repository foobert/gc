var compression = require('compression');
var express = require('express');
var app = express();
app.set('x-powered-by', false);
app.use(compression());
app.use('/assets', express.static('assets'));
app.get('/*', function(req, res, next) { res.sendFile('index.html', {root: __dirname}); });
app.listen(8080);
