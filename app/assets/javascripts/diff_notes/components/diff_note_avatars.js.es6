(() => {
  const DiffNoteAvatars = Vue.extend({
    props: ['discussionId'],
    data() {
      return {
        storeState: CommentsStore.state,
      }
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
          :title="note.authorName + ': ' + note.noteTruncated"
          :src="note.authorAvatar"
          @click="clickedAvatar($event)" />
        <span v-if="notesCount > 3"
          class="diff-comments-more-count has-tooltip"
          data-container="body"
          data-placement="top"
          ref="extraComments"
          :title="extraNotesTitle">+{{ notesCount - 3 }}</span>
      </div>
    `,
    watch: {
      storeState: {
        handler() {
          this.$nextTick(() => {
            const notesCount = this.notesCount;

            $(this.$refs.extraComments).tooltip('fixTitle');

            // We need to add/remove a class to an element that is outside the Vue instance
            if (Cookies.get('diff_view') === 'parallel') {
              if (notesCount) {
                this.$el.closest('.diff-line-num').classList.add('js-no-comment-btn');
              } else {
                this.$el.closest('.diff-line-num').classList.remove('js-no-comment-btn');
              }
            } else {
              if (notesCount) {
                this.$el.closest('.line_holder').classList.add('js-no-comment-btn');
              } else {
                this.$el.closest('.line_holder').classList.remove('js-no-comment-btn');
              }
            }
          });
        },
        deep: true,
      },
    },
    computed: {
      notesSubset() {
        let notes = [];
        let index = 0;

        if (this.discussion) {
          for (const noteId in this.discussion.notes) {
            if (index < 3) {
              notes.push(this.discussion.notes[noteId]);
            }

            index++;
          }
        }

        return notes;
      },
      extraNotesTitle() {
        if (this.discussion) {
          const extra = this.discussion.notesCount() - 3;

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
        Notes.prototype.addDiffNote(e);
      }
    }
  });

  Vue.component('diff-note-avatars', DiffNoteAvatars);
})();
