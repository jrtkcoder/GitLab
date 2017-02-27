/**
 * Renders Rollback or Re deploy button in environments table depending
 * of the provided property `isLastDeployment`
 */
import Vue from 'vue';

export default Vue.component('rollback-component', {
  props: {
    retryUrl: {
      type: String,
      default: '',
    },

    isLastDeployment: {
      type: Boolean,
      default: true,
    },
  },

  template: `
    <a class="btn" :href="retryUrl" data-method="post" rel="nofollow">
      <span v-if="isLastDeployment">
        Re-deploy
      </span>
      <span v-else>
        Rollback
      </span>
    </a>
  `,
});
