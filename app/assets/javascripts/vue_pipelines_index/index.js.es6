/* eslint-disable no-param-reassign */

import Vue from 'vue';
import VueResource from 'vue-resource';
import '../lib/utils/common_utils';
import '../vue_shared/vue_resource_interceptor';
import './pipelines';

window.Vue = Vue;
Vue.use(VueResource);

$(() => new Vue({
  el: document.querySelector('.vue-pipelines-index'),

  data() {
    const project = document.querySelector('.pipelines');
    const svgs = document.querySelector('.pipeline-svgs').dataset;

    // Transform svgs DOMStringMap to a plain Object.
    const svgsObject = gl.utils.DOMStringMapToObject(svgs);

    return {
      scope: project.dataset.url,
      store: new gl.PipelineStore(),
      svgs: svgsObject,
    };
  },
  components: {
    'vue-pipelines': gl.VuePipelines,
  },
  template: `
    <vue-pipelines
      :scope='scope'
      :store='store'
      :svgs='svgs'
    >
    </vue-pipelines>
  `,
}));
