var webpack = require('webpack');
var autoprefixer = require('autoprefixer-core');
var path = require('path');

module.exports = {
    entry: [
        'webpack-dev-server/client?http://0.0.0.0:9090',
        'webpack/hot/only-dev-server',
        './src/index.coffee'
    ],
    output: {
        path: path.join(__dirname, 'assets'),
        publicPath: "/assets/",
        filename: "bundle.js"
    },
    devtool: "cheap-module-eval-source-map",
    module: {
        loaders: [
            { test: /\.css$/, loaders: ['style', 'css', 'postcss'] },
            { test: /\.coffee$/, loaders: ['coffee'] },
            { test: /\.js$/, exclude: /node_modules/, loaders: ['babel?optional[]=runtime&stage=1'] },
            { test: /\.cjsx$/, loaders: ['react-hot', 'coffee', 'cjsx']},
            { test: /\.(jpe?g|png|gif|svg)$/i, loaders: [ 'url?limit=2048!file?hash=sha512&digest=hex&name=[hash].[ext]' ] },
            { test: /\.(woff2?|ttf|eot)$/i, loaders: [ 'file?hash=sha512&digest=hex&name=[hash].[ext]' ] }
        ]
    },
    postcss: [ autoprefixer({ browsers: ['last 2 version'] }) ],
    plugins: [
        new webpack.HotModuleReplacementPlugin(),
        new webpack.NoErrorsPlugin()
    ]
};
