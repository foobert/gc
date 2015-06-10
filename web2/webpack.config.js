module.exports = {
    entry: "./js/index.coffee",
    output: {
        path: __dirname,
        filename: "bundle.js"
    },
    devtool: "source-map",
    module: {
        loaders: [
            { test: /\.css$/, loader: "style!css" },
            { test: /\.coffee$/, loader: "coffee-loader" },
            { test: /\.cjsx$/, loaders: ['coffee', 'cjsx']}
        ]
    }
};
