/* eslint-disable no-new, no-param-reassign */
/* global Vue, CommitsPipelineStore, PipelinesService, Flash */

window.Vue = require('vue');
window.Vue.use(require('vue-resource'));
require('../../lib/utils/common_utils');
require('../../vue_shared/vue_resource_interceptor');
require('../../vue_shared/components/pipelines_table');
require('../../vue_realtime_listener/index');
require('./pipelines_service');
require('./pipelines_store');

/**
 *
 * Uses `pipelines-table-component` to render Pipelines table with an API call.
 * Endpoint is provided in HTML and passed as `endpoint`.
 * We need a store to store the received environemnts.
 * We need a service to communicate with the server.
 *
 * Necessary SVG in the table are provided as props. This should be refactored
 * as soon as we have Webpack and can load them directly into JS files.
 */

(() => {
  window.gl = window.gl || {};
  gl.commits = gl.commits || {};
  gl.commits.pipelines = gl.commits.pipelines || {};

  gl.commits.pipelines.PipelinesTableView = Vue.component('pipelines-table', {

    components: {
      'pipelines-table-component': gl.pipelines.PipelinesTableComponent,
    },

    /**
     * Accesses the DOM to provide the needed data.
     * Returns the necessary props to render `pipelines-table-component` component.
     *
     * @return {Object}
     */
    data() {
      const pipelinesTableData = document.querySelector('#commit-pipeline-table-view').dataset;
      const svgsData = document.querySelector('.pipeline-svgs').dataset;
      const store = new gl.commits.pipelines.PipelinesStore();

      // Transform svgs DOMStringMap to a plain Object.
      const svgsObject = gl.utils.DOMStringMapToObject(svgsData);

      return {
        endpoint: pipelinesTableData.endpoint,
        svgs: svgsObject,
        store,
        state: store.state,
        isLoading: false,
      };
    },

    /**
     * When the component is created the service to fetch the data will be
     * initialized with the correct endpoint.
     *
     * A request to fetch the pipelines will be made.
     * In case of a successfull response we will store the data in the provided
     * store, in case of a failed response we need to warn the user.
     *
     */
    created() {
      const pipelinesService = new gl.commits.pipelines.PipelinesService(this.endpoint);

      this.isLoading = true;
      return pipelinesService.all()
        .then(response => response.json())
        .then((json) => {
          this.store.storePipelines(json);
          this.store.startTimeAgoLoops.call(this, Vue);
          this.isLoading = false;
        })
        .catch(() => {
          this.isLoading = false;
          new Flash('An error occurred while fetching the pipelines, please reload the page again.', 'alert');
        });
    },

    template: `
      <div>
        <div class="pipelines realtime-loading" v-if="isLoading">
          <i class="fa fa-spinner fa-spin"></i>
        </div>

        <div class="blank-state blank-state-no-icon"
          v-if="!isLoading && state.pipelines.length === 0">
          <h2 class="blank-state-title js-blank-state-title">
            No pipelines to show
          </h2>
        </div>

        <div class="table-holder pipelines"
          v-if="!isLoading && state.pipelines.length > 0">
          <pipelines-table-component
            :pipelines="state.pipelines"
            :svgs="svgs">
          </pipelines-table-component>
        </div>
      </div>
    `,
  });
})();
