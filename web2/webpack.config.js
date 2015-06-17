module.exports = {
    entry: "./src/index.coffee",
    output: {
        path: __dirname,
        filename: "bundle.js"
    },
    devtool: "source-map",
    module: {
        loaders: [
            { test: /\.css$/, loader: "style!css" },
            { test: /\.coffee$/, loader: "coffee-loader" },
            { test: /\.cjsx$/, loaders: ['coffee', 'cjsx']},
            { test: /\.(jpe?g|png|gif|svg)$/i, loaders: [ 'file?hash=sha512&digest=hex&name=[hash].[ext]' ] },
            { test: /\.(woff2?|ttf|eot)$/i, loaders: [ 'file?hash=sha512&digest=hex&name=[hash].[ext]' ] }
        ]
    }
};
