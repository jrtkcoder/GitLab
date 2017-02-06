/* global Vue */

require('./tabs');

(() => {
  const ModalStore = gl.issueBoards.ModalStore;

  gl.issueBoards.ModalHeader = Vue.extend({
    mixins: [gl.issueBoards.ModalMixins],
    data() {
      return ModalStore.store;
    },
    computed: {
      selectAllText() {
        if (ModalStore.selectedCount() !== this.issues.length || this.issues.length === 0) {
          return 'Select all';
        }

        return 'Deselect all';
      },
      showSearch() {
        return this.activeTab === 'all' && !this.loading && this.issuesCount > 0;
      },
    },
    methods: {
      toggleAll() {
        this.$refs.selectAllBtn.blur();

        ModalStore.toggleAll();
      },
    },
    components: {
      'modal-tabs': gl.issueBoards.ModalTabs,
    },
    template: `
      <div>
        <header class="add-issues-header form-actions">
          <h2>
            Add issues
            <button
              type="button"
              class="close"
              data-dismiss="modal"
              aria-label="Close"
              @click="toggleModal(false)">
              <span aria-hidden="true">×</span>
            </button>
          </h2>
        </header>
        <modal-tabs v-if="!loading && issuesCount > 0"></modal-tabs>
        <div
          class="add-issues-search append-bottom-10"
          v-if="showSearch">
          <input
            placeholder="Search issues..."
            class="form-control"
            type="search"
            v-model="searchTerm" />
          <button
            type="button"
            class="btn btn-success btn-inverted prepend-left-10"
            ref="selectAllBtn"
            @click="toggleAll">
            {{ selectAllText }}
          </button>
        </div>
      </div>
    `,
  });
})();
