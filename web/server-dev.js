var webpack = require('webpack');
var WebpackDevServer = require('webpack-dev-server');
var config = require('./webpack.config');

config.plugins.push(new webpack.HotModuleReplacementPlugin());
config.plugins.push(new webpack.NoErrorsPlugin());
config.entry.push('webpack-dev-server/client?http://0.0.0.0:9090');
config.entry.push('webpack/hot/only-dev-server');

new WebpackDevServer(webpack(config), {
    publicPath: config.output.publicPath,
    hot: true,
    historyApiFallback: true,
}).listen(9090, 'localhost', function (err, result) {
    if (err) { console.log(err); }
    console.log('Listening at localhost:9090');
});
