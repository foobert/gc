var autoprefixer = require('autoprefixer-core');

module.exports = {
    entry: "./src/index.coffee",
    output: {
        path: './assets',
        publicPath: "assets/",
        filename: "bundle.js"
    },
    devtool: "cheap-module-eval-source-map",
    module: {
        loaders: [
            { test: /^css\/\.css$/, loader: "style!css!postcss" },
            { test: /\.css$/, loader: "style!css" },
            { test: /\.coffee$/, loader: "coffee-loader" },
            { test: /\.cjsx$/, loaders: ['coffee', 'cjsx']},
            { test: /\.(jpe?g|png|gif|svg)$/i, loaders: [ 'url?limit=2048!file?hash=sha512&digest=hex&name=[hash].[ext]' ] },
            { test: /\.(woff2?|ttf|eot)$/i, loaders: [ 'file?hash=sha512&digest=hex&name=[hash].[ext]' ] }
        ]
    },
    postcss: [ autoprefixer({ browsers: ['last 2 version'] }) ]
};
