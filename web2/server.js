var compression = require('compression');
var express = require('express');
var logger = require('morgan');
var app = express();
app.set('x-powered-by', false);
app.use(compression());
app.use(logger(process.env.NODE_ENV === 'production' ? 'tiny' : 'dev'));
app.use('/assets', express.static('assets'));
app.get('/*', function(req, res, next) { res.sendFile('index.html', {root: __dirname}); });
console.log('Listening on 8080');
app.listen(8080);
