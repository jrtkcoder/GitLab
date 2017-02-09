'use strict';

var fs = require('fs');
var path = require('path');
var webpack = require('webpack');
var StatsPlugin = require('stats-webpack-plugin');
var CompressionPlugin = require('compression-webpack-plugin');

var ROOT_PATH = path.resolve(__dirname, '..');
var IS_PRODUCTION = process.env.NODE_ENV === 'production';
var IS_DEV_SERVER = process.argv[1].indexOf('webpack-dev-server') !== -1;
var DEV_SERVER_PORT = parseInt(process.env.DEV_SERVER_PORT, 10) || 3808;

var config = {
  context: path.join(ROOT_PATH, 'app/assets/javascripts'),
  entry: {
    application:          './application.js',
    blob_edit:            './blob_edit/blob_edit_bundle.js',
    boards:               './boards/boards_bundle.js',
    simulate_drag:        './test_utils/simulate_drag.js',
    cycle_analytics:      './cycle_analytics/cycle_analytics_bundle.js',
    commit_pipelines:     './commit/pipelines/pipelines_bundle.js',
    diff_notes:           './diff_notes/diff_notes_bundle.js',
    environments:         './environments/environments_bundle.js',
    filtered_search:      './filtered_search/filtered_search_bundle.js',
    graphs:               './graphs/graphs_bundle.js',
    issuable:             './issuable/issuable_bundle.js',
    merge_conflicts:      './merge_conflicts/merge_conflicts_bundle.js',
    merge_request_widget: './merge_request_widget/ci_bundle.js',
    network:              './network/network_bundle.js',
    profile:              './profile/profile_bundle.js',
    protected_branches:   './protected_branches/protected_branches_bundle.js',
    snippet:              './snippet/snippet_bundle.js',
    terminal:             './terminal/terminal_bundle.js',
    users:                './users/users_bundle.js',
    lib_chart:            './lib/chart.js',
    lib_d3:               './lib/d3.js',
    lib_vue:              './lib/vue_resource.js',
    vue_pipelines:        './vue_pipelines_index/index.js',
  },

  output: {
    path: path.join(ROOT_PATH, 'public/assets/webpack'),
    publicPath: '/assets/webpack/',
    filename: IS_PRODUCTION ? '[name]-[chunkhash].js' : '[name].js'
  },

  devtool: 'inline-source-map',

  module: {
    loaders: [
      {
        test: /\.(js|es6)$/,
        exclude: /(node_modules|vendor\/assets)/,
        loader: 'babel-loader',
        query: {
          // 'use strict' was broken in sprockets-es6 due to sprockets concatination method.
          // many es5 strict errors which were never caught ended up in our es6 assets as a result.
          // this hack is necessary until they can be fixed.
          blacklist: ['useStrict']
        }
      },
      {
        test: /\.(js|es6)$/,
        loader: 'imports-loader',
        query: 'this=>window'
      },
      {
        test: /\.json$/,
        loader: 'json-loader'
      }
    ]
  },

  plugins: [
    // manifest filename must match config.webpack.manifest_filename
    // webpack-rails only needs assetsByChunkName to function properly
    new StatsPlugin('manifest.json', {
      chunkModules: false,
      source: false,
      chunks: false,
      modules: false,
      assets: true
    }),
    new CompressionPlugin({
      asset: '[path].gz[query]',
    }),
  ],

  resolve: {
    extensions: ['', '.js', '.es6', '.js.es6'],
    alias: {
      '~':              path.join(ROOT_PATH, 'app/assets/javascripts'),
      'bootstrap/js':   'bootstrap-sass/assets/javascripts/bootstrap',
      'emoji-aliases$': path.join(ROOT_PATH, 'fixtures/emojis/aliases.json'),
      'vendor':         path.join(ROOT_PATH, 'vendor/assets/javascripts'),
      'vue$':           'vue/dist/vue.js',
      'vue-resource$':  'vue-resource/dist/vue-resource.js'
    }
  }
}

if (IS_PRODUCTION) {
  config.devtool = 'source-map';
  config.plugins.push(
    new webpack.NoErrorsPlugin(),
    new webpack.optimize.UglifyJsPlugin({
      compress: { warnings: false }
    }),
    new webpack.DefinePlugin({
      'process.env': { NODE_ENV: JSON.stringify('production') }
    }),
    new webpack.optimize.DedupePlugin(),
    new webpack.optimize.OccurrenceOrderPlugin()
  );
}

if (IS_DEV_SERVER) {
  config.devServer = {
    port: DEV_SERVER_PORT,
    headers: { 'Access-Control-Allow-Origin': '*' }
  };
  config.output.publicPath = '//localhost:' + DEV_SERVER_PORT + config.output.publicPath;
}

module.exports = config;
