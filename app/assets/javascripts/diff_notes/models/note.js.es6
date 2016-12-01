/* eslint-disable */
class NoteModel {
  constructor (discussionId, noteId, canResolve, resolved, resolved_by, authorName, authorAvatar, noteTruncated) {
    this.discussionId = discussionId;
    this.id = noteId;
    this.canResolve = canResolve;
    this.resolved = resolved;
    this.resolved_by = resolved_by;
    this.authorName = authorName;
    this.authorAvatar = authorAvatar;
    this.noteTruncated = noteTruncated;
  }
}
