var express = require('express');
var app = express();
app.use('/assets', express.static('assets'));
app.use('/img', express.static('img'));
app.get('/*', function(req, res, next) { res.sendFile('index.html', {root: __dirname}); });
app.listen(8080);
