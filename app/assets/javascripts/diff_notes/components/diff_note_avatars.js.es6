/* global Vue CommentsStore Cookies notes */
(() => {
  const DiffNoteAvatars = Vue.extend({
    props: ['discussionId'],
    data() {
      return {
        isVisible: false,
        lineType: '',
        storeState: CommentsStore.state,
        shownAvatars: 3,
      };
    },
    template: `
      <div class="diff-comment-avatar-holders"
        v-show="notesCount !== 0">
        <div v-if="!isVisible">
          <img v-for="note in notesSubset"
            class="avatar diff-comment-avatar has-tooltip js-diff-comment-avatar"
            width="19"
            height="19"
            role="button"
            data-container="body"
            data-placement="top"
            :data-line-type="lineType"
            :title="note.authorName + ': ' + note.noteTruncated"
            :src="note.authorAvatar"
            @click="clickedAvatar($event)" />
          <span v-if="notesCount > shownAvatars"
            class="diff-comments-more-count has-tooltip js-diff-comment-avatar"
            data-container="body"
            data-placement="top"
            ref="extraComments"
            role="button"
            :data-line-type="lineType"
            :title="extraNotesTitle"
            @click="clickedAvatar($event)">{{ moreText }}</span>
        </div>
        <button class="diff-notes-collapse js-diff-comment-avatar"
          type="button"
          aria-label="Show comments"
          :data-line-type="lineType"
          @click="clickedAvatar($event)"
          v-if="isVisible">
          <svg width="11" height="11" viewBox="0 0 9 13"><path d="M2.57568253,6.49866948 C2.50548852,6.57199715 2.44637866,6.59708255 2.39835118,6.57392645 C2.3503237,6.55077034 2.32631032,6.48902165 2.32631032,6.38867852 L2.32631032,-2.13272614 C2.32631032,-2.23306927 2.3503237,-2.29481796 2.39835118,-2.31797406 C2.44637866,-2.34113017 2.50548852,-2.31604477 2.57568253,-2.24271709 L6.51022184,1.86747129 C6.53977721,1.8983461 6.56379059,1.93500939 6.5822627,1.97746225 L6.5822627,2.27849013 C6.56379059,2.31708364 6.53977721,2.35374693 6.51022184,2.38848109 L2.57568253,6.49866948 Z" transform="translate(4.454287, 2.127976) rotate(90.000000) translate(-4.454287, -2.127976) "></path><path d="M3.74312342,2.09553332 C3.74312342,1.99519019 3.77821989,1.9083561 3.8484139,1.83502843 C3.91860791,1.76170075 4.00173115,1.72503747 4.09778611,1.72503747 L4.80711151,1.72503747 C4.90316647,1.72503747 4.98628971,1.76170075 5.05648372,1.83502843 C5.12667773,1.9083561 5.16177421,1.99519019 5.16177421,2.09553332 L5.16177421,10.2464421 C5.16177421,10.3467853 5.12667773,10.4336194 5.05648372,10.506947 C4.98628971,10.5802747 4.90316647,10.616938 4.80711151,10.616938 L4.09778611,10.616938 C4.00173115,10.616938 3.91860791,10.5802747 3.8484139,10.506947 C3.77821989,10.4336194 3.74312342,10.3467853 3.74312342,10.2464421 L3.74312342,2.09553332 Z" transform="translate(4.452449, 6.170988) rotate(-90.000000) translate(-4.452449, -6.170988) "></path><path d="M2.57568253,14.6236695 C2.50548852,14.6969971 2.44637866,14.7220826 2.39835118,14.6989264 C2.3503237,14.6757703 2.32631032,14.6140216 2.32631032,14.5136785 L2.32631032,5.99227386 C2.32631032,5.89193073 2.3503237,5.83018204 2.39835118,5.80702594 C2.44637866,5.78386983 2.50548852,5.80895523 2.57568253,5.88228291 L6.51022184,9.99247129 C6.53977721,10.0233461 6.56379059,10.0600094 6.5822627,10.1024622 L6.5822627,10.4034901 C6.56379059,10.4420836 6.53977721,10.4787469 6.51022184,10.5134811 L2.57568253,14.6236695 Z" transform="translate(4.454287, 10.252976) scale(1, -1) rotate(90.000000) translate(-4.454287, -10.252976) "></path></svg>
        </button>
      </div>
    `,
    mounted() {
      this.$nextTick(() => {
        this.addNoCommentClass();
        this.setDiscussionVisible();

        this.lineType = $(this.$el).closest('.diff-line-num').hasClass('old_line') ? 'old' : 'new';
      });
    },
    watch: {
      storeState: {
        handler() {
          this.$nextTick(() => {
            $('.has-tooltip', this.$el).tooltip('fixTitle');

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
      moreText() {
        const plusSign = this.notesCount < 100 ? '+' : '';

        return `${plusSign}${this.notesCount - this.shownAvatars}`;
      },
    },
    methods: {
      clickedAvatar(e) {
        notes.addDiffNote(e);

        // Toggle the active state of the toggle all button
        this.toggleDiscussionsToggleState();
        this.setDiscussionVisible();

        this.$nextTick(() => {
          $('.has-tooltip', this.$el).tooltip('fixTitle');
          $('.has-tooltip', this.$el).tooltip('hide');
        });
      },
      addNoCommentClass() {
        const notesCount = this.notesCount;

        $(this.$el).closest('.js-avatar-container')
          .toggleClass('js-no-comment-btn', notesCount > 0)
          .nextUntil('.js-avatar-container')
          .toggleClass('js-no-comment-btn', notesCount > 0);
      },
      toggleDiscussionsToggleState() {
        const $notesHolders = $(this.$el).closest('.code').find('.notes_holder');
        const $visibleNotesHolders = $notesHolders.filter(':visible');
        const $toggleDiffCommentsBtn = $(this.$el).closest('.diff-file').find('.js-toggle-diff-comments');

        $toggleDiffCommentsBtn.toggleClass('active', $notesHolders.length === $visibleNotesHolders.length);
      },
      setDiscussionVisible() {
        this.isVisible = $(`.diffs .notes[data-discussion-id="${this.discussion.id}"]`).is(':visible');
      },
    },
  });

  Vue.component('diff-note-avatars', DiffNoteAvatars);
})();
