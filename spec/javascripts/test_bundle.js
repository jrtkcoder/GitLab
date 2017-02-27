// enable test fixtures
import 'jasmine-jquery';

jasmine.getFixtures().fixturesPath = 'base/spec/javascripts/fixtures';
jasmine.getJSONFixtures().fixturesPath = 'base/spec/javascripts/fixtures';

// include common libraries
import jQuery from 'jquery';
import _ from 'underscore';
import Cookies from 'js-cookie';
import Vue from 'vue';
import VueResource from 'vue-resource';
import 'jquery-ujs';
import 'bootstrap/js/affix';
import 'bootstrap/js/alert';
import 'bootstrap/js/button';
import 'bootstrap/js/collapse';
import 'bootstrap/js/dropdown';
import 'bootstrap/js/modal';
import 'bootstrap/js/scrollspy';
import 'bootstrap/js/tab';
import 'bootstrap/js/transition';
import 'bootstrap/js/tooltip';
import 'bootstrap/js/popover';

window.$ = window.jQuery = jQuery;
window._ = _;
window.Cookies = Cookies;
window.Vue = Vue;
window.Vue.use(VueResource);

// stub expected globals
window.gl = window.gl || {};
window.gl.TEST_HOST = 'http://test.host';
window.gon = window.gon || {};

// render all of our tests
const testsContext = require.context('.', true, /_spec$/);
testsContext.keys().forEach(function (path) {
  try {
    testsContext(path);
  } catch (err) {
    console.error('[ERROR] Unable to load spec: ', path);
    describe('Test bundle', function () {
      it(`includes '${path}'`, function () {
        expect(err).toBeNull();
      });
    });
  }
});

// workaround: include all source files to find files with 0% coverage
// see also https://github.com/deepsweet/istanbul-instrumenter-loader/issues/15
describe('Uncovered files', function () {
  // the following files throw errors because of undefined variables
  const troubleMakers = [
    './blob_edit/blob_edit_bundle.js',
    './cycle_analytics/components/stage_plan_component.js',
    './cycle_analytics/components/stage_staging_component.js',
    './cycle_analytics/components/stage_test_component.js',
    './diff_notes/components/jump_to_discussion.js',
    './diff_notes/components/resolve_count.js',
    './merge_conflicts/components/inline_conflict_lines.js',
    './merge_conflicts/components/parallel_conflict_lines.js',
    './network/branch_graph.js',
  ];

  const sourceFiles = require.context('~', true, /^\.\/(?!application\.js).*\.(js|es6)$/);
  sourceFiles.keys().forEach(function (path) {
    // ignore if there is a matching spec file
    if (testsContext.keys().indexOf(`${path.replace(/\.js(\.es6)?$/, '')}_spec`) > -1) {
      return;
    }

    it(`includes '${path}'`, function () {
      try {
        sourceFiles(path);
      } catch (err) {
        if (troubleMakers.indexOf(path) === -1) {
          expect(err).toBeNull();
        }
      }
    });
  });
});
