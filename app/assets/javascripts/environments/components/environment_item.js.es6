/* global Vue */
/* global timeago */

window.Vue = require('vue');
window.timeago = require('vendor/timeago');
require('../../lib/utils/text_utility');
require('../../vue_shared/components/commit');
require('./environment_actions');
require('./environment_external_url');
require('./environment_stop');
require('./environment_rollback');
require('./environment_terminal_button');

(() => {
  /**
   * Envrionment Item Component
   *
   * Used in a hierarchical structure to show folders with children
   * in a table.
   * Recursive component based on [Tree View](https://vuejs.org/examples/tree-view.html)
   *
   * See this [issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/22539)
   * for more information.15
   */

  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};
  window.gl.environmentsList.timeagoInstance = new timeago(); // eslint-disable-line

  gl.environmentsList.EnvironmentItem = Vue.component('environment-item', {

    components: {
      'commit-component': gl.CommitComponent,
      'actions-component': gl.environmentsList.ActionsComponent,
      'external-url-component': gl.environmentsList.ExternalUrlComponent,
      'stop-component': gl.environmentsList.StopComponent,
      'rollback-component': gl.environmentsList.RollbackComponent,
      'terminal-button-component': gl.environmentsList.TerminalButtonComponent,
    },

    props: {
      model: {
        type: Object,
        required: true,
        default: () => ({}),
      },

      toggleRow: {
        type: Function,
        required: false,
      },

      canCreateDeployment: {
        type: Boolean,
        required: false,
        default: false,
      },

      canReadEnvironment: {
        type: Boolean,
        required: false,
        default: false,
      },

      commitIconSvg: {
        type: String,
        required: false,
      },

      playIconSvg: {
        type: String,
        required: false,
      },

      terminalIconSvg: {
        type: String,
        required: false,
      },

    },

    data() {
      return {
        rowClass: {
          'children-row': this.model['vue-isChildren'],
        },
      };
    },

    computed: {

      /**
       * If an item has a `children` entry it means it is a folder.
       * Folder items have different behaviours - it is possible to toggle
       * them and show their children.
       *
       * @returns {Boolean|Undefined}
       */
      isFolder() {
        return this.model.children && this.model.children.length > 0;
      },

      /**
       * If an item is inside a folder structure will return true.
       * Used for css purposes.
       *
       * @returns {Boolean|undefined}
       */
      isChildren() {
        return this.model['vue-isChildren'];
      },

      /**
       * Counts the number of environments in each folder.
       * Used to show a badge with the counter.
       *
       * @returns {Number|Undefined}  The number of environments for the current folder.
       */
      childrenCounter() {
        return this.model.children && this.model.children.length;
      },

      /**
       * Verifies if `last_deployment` key exists in the current Envrionment.
       * This key is required to render most of the html - this method works has
       * an helper.
       *
       * @returns {Boolean}
       */
      hasLastDeploymentKey() {
        if (this.model.last_deployment &&
          !this.$options.isObjectEmpty(this.model.last_deployment)) {
          return true;
        }
        return false;
      },

      /**
       * Verifies is the given environment has manual actions.
       * Used to verify if we should render them or nor.
       *
       * @returns {Boolean|Undefined}
       */
      hasManualActions() {
        return this.model.last_deployment && this.model.last_deployment.manual_actions &&
          this.model.last_deployment.manual_actions.length > 0;
      },

      /**
       * Returns the value of the `stop_action?` key provided in the response.
       *
       * @returns {Boolean}
       */
      hasStopAction() {
        return this.model['stop_action?'];
      },

      /**
       * Verifies if the `deployable` key is present in `last_deployment` key.
       * Used to verify whether we should or not render the rollback partial.
       *
       * @returns {Boolean|Undefined}
       */
      canRetry() {
        return this.hasLastDeploymentKey &&
          this.model.last_deployment &&
          this.model.last_deployment.deployable;
      },

      /**
       * Verifies if the date to be shown is present.
       *
       * @returns {Boolean|Undefined}
       */
      canShowDate() {
        return this.model.last_deployment &&
          this.model.last_deployment.deployable &&
          this.model.last_deployment.deployable !== undefined;
      },

      /**
       * Human readable date.
       *
       * @returns {String}
       */
      createdDate() {
        return gl.environmentsList.timeagoInstance.format(
          this.model.last_deployment.deployable.created_at,
        );
      },

      /**
       * Returns the manual actions with the name parsed.
       *
       * @returns {Array.<Object>|Undefined}
       */
      manualActions() {
        if (this.hasManualActions) {
          return this.model.last_deployment.manual_actions.map((action) => {
            const parsedAction = {
              name: gl.text.humanize(action.name),
              play_path: action.play_path,
            };
            return parsedAction;
          });
        }
        return [];
      },

      /**
       * Builds the string used in the user image alt attribute.
       *
       * @returns {String}
       */
      userImageAltDescription() {
        if (this.model.last_deployment &&
          this.model.last_deployment.user &&
          this.model.last_deployment.user.username) {
          return `${this.model.last_deployment.user.username}'s avatar'`;
        }
        return '';
      },

      /**
       * If provided, returns the commit tag.
       *
       * @returns {String|Undefined}
       */
      commitTag() {
        if (this.model.last_deployment &&
          this.model.last_deployment.tag) {
          return this.model.last_deployment.tag;
        }
        return undefined;
      },

      /**
       * If provided, returns the commit ref.
       *
       * @returns {Object|Undefined}
       */
      commitRef() {
        if (this.model.last_deployment && this.model.last_deployment.ref) {
          return this.model.last_deployment.ref;
        }
        return undefined;
      },

      /**
       * If provided, returns the commit url.
       *
       * @returns {String|Undefined}
       */
      commitUrl() {
        if (this.model.last_deployment &&
          this.model.last_deployment.commit &&
          this.model.last_deployment.commit.commit_path) {
          return this.model.last_deployment.commit.commit_path;
        }
        return undefined;
      },

      /**
       * If provided, returns the commit short sha.
       *
       * @returns {String|Undefined}
       */
      commitShortSha() {
        if (this.model.last_deployment &&
          this.model.last_deployment.commit &&
          this.model.last_deployment.commit.short_id) {
          return this.model.last_deployment.commit.short_id;
        }
        return undefined;
      },

      /**
       * If provided, returns the commit title.
       *
       * @returns {String|Undefined}
       */
      commitTitle() {
        if (this.model.last_deployment &&
          this.model.last_deployment.commit &&
          this.model.last_deployment.commit.title) {
          return this.model.last_deployment.commit.title;
        }
        return undefined;
      },

      /**
       * If provided, returns the commit tag.
       *
       * @returns {Object|Undefined}
       */
      commitAuthor() {
        if (this.model.last_deployment &&
          this.model.last_deployment.commit &&
          this.model.last_deployment.commit.author) {
          return this.model.last_deployment.commit.author;
        }

        return undefined;
      },

      /**
       * Verifies if the `retry_path` key is present and returns its value.
       *
       * @returns {String|Undefined}
       */
      retryUrl() {
        if (this.model.last_deployment &&
          this.model.last_deployment.deployable &&
          this.model.last_deployment.deployable.retry_path) {
          return this.model.last_deployment.deployable.retry_path;
        }
        return undefined;
      },

      /**
       * Verifies if the `last?` key is present and returns its value.
       *
       * @returns {Boolean|Undefined}
       */
      isLastDeployment() {
        return this.model.last_deployment && this.model.last_deployment['last?'];
      },

      /**
       * Builds the name of the builds needed to display both the name and the id.
       *
       * @returns {String}
       */
      buildName() {
        if (this.model.last_deployment &&
          this.model.last_deployment.deployable) {
          return `${this.model.last_deployment.deployable.name} #${this.model.last_deployment.deployable.id}`;
        }
        return '';
      },

      /**
       * Builds the needed string to show the internal id.
       *
       * @returns {String}
       */
      deploymentInternalId() {
        if (this.model.last_deployment &&
          this.model.last_deployment.iid) {
          return `#${this.model.last_deployment.iid}`;
        }
        return '';
      },

      /**
       * Verifies if the user object is present under last_deployment object.
       *
       * @returns {Boolean}
       */
      deploymentHasUser() {
        return !this.$options.isObjectEmpty(this.model.last_deployment) &&
          !this.$options.isObjectEmpty(this.model.last_deployment.user);
      },

      /**
       * Returns the user object nested with the last_deployment object.
       * Used to render the template.
       *
       * @returns {Object}
       */
      deploymentUser() {
        if (!this.$options.isObjectEmpty(this.model.last_deployment) &&
          !this.$options.isObjectEmpty(this.model.last_deployment.user)) {
          return this.model.last_deployment.user;
        }
        return {};
      },

      /**
       * Verifies if the build name column should be rendered by verifing
       * if all the information needed is present
       * and if the environment is not a folder.
       *
       * @returns {Boolean}
       */
      shouldRenderBuildName() {
        return !this.isFolder &&
          !this.$options.isObjectEmpty(this.model.last_deployment) &&
          !this.$options.isObjectEmpty(this.model.last_deployment.deployable);
      },

      /**
       * Verifies if deplyment internal ID should be rendered by verifing
       * if all the information needed is present
       * and if the environment is not a folder.
       *
       * @returns {Boolean}
       */
      shouldRenderDeploymentID() {
        return !this.isFolder &&
          !this.$options.isObjectEmpty(this.model.last_deployment) &&
          this.model.last_deployment.iid !== undefined;
      },
    },

    /**
     * Helper to verify if certain given object are empty.
     * Should be replaced by lodash _.isEmpty - https://lodash.com/docs/4.17.2#isEmpty
     * @param  {Object} object
     * @returns {Bollean}
     */
    isObjectEmpty(object) {
      for (const key in object) { // eslint-disable-line
        if (hasOwnProperty.call(object, key)) {
          return false;
        }
      }
      return true;
    },

    template: `
      <tr>
        <td v-bind:class="{ 'children-row': isChildren}">
          <a v-if="!isFolder"
            class="environment-name"
            :href="model.environment_path">
            {{model.name}}
          </a>
          <span v-else v-on:click="toggleRow(model)" class="folder-name">
            <span class="folder-icon">
              <i v-show="model.isOpen" class="fa fa-caret-down"></i>
              <i v-show="!model.isOpen" class="fa fa-caret-right"></i>
            </span>

            <span>
              {{model.name}}
            </span>

            <span class="badge">
              {{childrenCounter}}
            </span>
          </span>
        </td>

        <td class="deployment-column">
          <span v-if="shouldRenderDeploymentID">
            {{deploymentInternalId}}
          </span>

          <span v-if="!isFolder && deploymentHasUser">
            by
            <a :href="deploymentUser.web_url" class="js-deploy-user-container">
              <img class="avatar has-tooltip s20"
                :src="deploymentUser.avatar_url"
                :alt="userImageAltDescription"
                :title="deploymentUser.username" />
            </a>
          </span>
        </td>

        <td class="environments-build-cell">
          <a v-if="shouldRenderBuildName"
            class="build-link"
            :href="model.last_deployment.deployable.build_path">
            {{buildName}}
          </a>
        </td>

        <td>
          <div v-if="!isFolder && hasLastDeploymentKey" class="js-commit-component">
            <commit-component
              :tag="commitTag"
              :commit-ref="commitRef"
              :commit-url="commitUrl"
              :short-sha="commitShortSha"
              :title="commitTitle"
              :author="commitAuthor"
              :commit-icon-svg="commitIconSvg">
            </commit-component>
          </div>
          <p v-if="!isFolder && !hasLastDeploymentKey" class="commit-title">
            No deployments yet
          </p>
        </td>

        <td>
          <span
            v-if="!isFolder && canShowDate"
            class="environment-created-date-timeago">
            {{createdDate}}
          </span>
        </td>

        <td class="hidden-xs">
          <div v-if="!isFolder">
            <div v-if="hasManualActions && canCreateDeployment"
              class="inline js-manual-actions-container">
              <actions-component
                :play-icon-svg="playIconSvg"
                :actions="manualActions">
              </actions-component>
            </div>

            <div v-if="model.external_url && canReadEnvironment"
              class="inline js-external-url-container">
              <external-url-component
                :external-url="model.external_url">
              </external-url-component>
            </div>

            <div v-if="hasStopAction && canCreateDeployment"
              class="inline js-stop-component-container">
              <stop-component
                :stop-url="model.stop_path">
              </stop-component>
            </div>

            <div v-if="model.terminal_path"
              class="inline js-terminal-button-container">
              <terminal-button-component
                :terminal-icon-svg="terminalIconSvg"
                :terminal-path="model.terminal_path">
              </terminal-button-component>
            </div>

            <div v-if="canRetry && canCreateDeployment"
              class="inline js-rollback-component-container">
              <rollback-component
                :is-last-deployment="isLastDeployment"
                :retry-url="retryUrl">
                </rollback-component>
            </div>
          </div>
        </td>
      </tr>
    `,
  });
})();
