/* global Vue CommentsStore Cookies notes */
(() => {
  const DiffNoteAvatars = Vue.extend({
    props: ['discussionId'],
    data() {
      return {
        lineType: '',
        storeState: CommentsStore.state,
        shownAvatars: 3,
      };
    },
    template: `
      <div class="diff-comment-avatar-holders">
        <img v-for="note in notesSubset"
          class="avatar diff-comment-avatar has-tooltip js-diff-comment-avatar"
          width="19"
          height="19"
          role="button"
          data-container="body"
          data-placement="top"
          data-html="true"
          :data-line-type="lineType"
          :title="note.authorName + ': ' + note.noteTruncated"
          :src="note.authorAvatar"
          @click="clickedAvatar($event)" />
        <span v-if="notesCount > shownAvatars"
          class="diff-comments-more-count has-tooltip js-diff-comment-avatar"
          data-container="body"
          data-placement="top"
          ref="extraComments"
          :title="extraNotesTitle"
          @click="clickedAvatar($event)">+{{ notesCount - shownAvatars }}</span>
      </div>
    `,
    mounted() {
      this.$nextTick(() => {
        this.addNoCommentClass();

        this.lineType = $(this.$el).closest('.diff-line-num').hasClass('old_line') ? 'old' : 'new';
      });
    },
    watch: {
      storeState: {
        handler() {
          this.$nextTick(() => {
            $(this.$refs.extraComments).tooltip('fixTitle');

            // We need to add/remove a class to an element that is outside the Vue instance
            this.addNoCommentClass();
          });
        },
        deep: true,
      },
    },
    computed: {
      notesSubset() {
        let notes = [];

        if (this.discussion) {
          notes = Object.keys(this.discussion.notes)
            .slice(0, this.shownAvatars)
            .map(noteId => this.discussion.notes[noteId]);
        }

        return notes;
      },
      extraNotesTitle() {
        if (this.discussion) {
          const extra = this.discussion.notesCount() - this.shownAvatars;

          return `${extra} more comment${extra > 1 ? 's' : ''}`;
        }

        return '';
      },
      discussion() {
        return this.storeState[this.discussionId];
      },
      notesCount() {
        if (this.discussion) {
          return this.discussion.notesCount();
        }

        return 0;
      },
    },
    methods: {
      clickedAvatar(e) {
        notes.addDiffNote(e);
      },
      addNoCommentClass() {
        const notesCount = this.notesCount;

        $(this.$el).closest('.js-no-comment-btn-detector')
          .toggleClass('js-no-comment-btn', notesCount > 0)
          .next('td')
          .toggleClass('js-no-comment-btn', notesCount > 0);
      },
    },
  });

  Vue.component('diff-note-avatars', DiffNoteAvatars);
})();
