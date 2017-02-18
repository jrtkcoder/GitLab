class Note < ActiveRecord::Base
  extend ActiveModel::Naming
  include Gitlab::CurrentSettings
  include Participable
  include Mentionable
  include Awardable
  include Importable
  include FasterCacheKeys
  include CacheMarkdownField
  include AfterCommitQueue
  include ResolvableNote

  cache_markdown_field :note, pipeline: :note

  # Attribute containing rendered and redacted Markdown as generated by
  # Banzai::ObjectRenderer.
  attr_accessor :redacted_note_html

  # An Array containing the number of visible references as generated by
  # Banzai::ObjectRenderer
  attr_accessor :user_visible_reference_count

  # Attribute used to store the attributes that have ben changed by slash commands.
  attr_accessor :commands_changes

  # The discussion ID for the `DiscussionNote` thread being replied to
  attr_accessor :in_reply_to_discussion_id

  default_value_for :system, false

  attr_mentionable :note, pipeline: :note
  participant :author

  belongs_to :project
  belongs_to :noteable, polymorphic: true, touch: true
  belongs_to :author, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  has_many :todos, dependent: :destroy
  has_many :events, as: :target, dependent: :destroy

  delegate :gfm_reference, :local_reference, to: :noteable
  delegate :name, to: :project, prefix: true
  delegate :name, :email, to: :author, prefix: true
  delegate :title, to: :noteable, allow_nil: true

  validates :note, presence: true
  validates :project, presence: true, unless: :for_personal_snippet?

  # Attachments are deprecated and are handled by Markdown uploader
  validates :attachment, file_size: { maximum: :max_attachment_size }

  validates :noteable_type, presence: true
  validates :noteable_id, presence: true, unless: [:for_commit?, :importing?]
  validates :commit_id, presence: true, if: :for_commit?
  validates :author, presence: true
  validates :discussion_id, presence: true, format: { with: /\A\h{40}\z/ }

  validate unless: [:for_commit?, :importing?, :for_personal_snippet?] do |note|
    unless note.noteable.try(:project) == note.project
      errors.add(:invalid_project, 'Note and noteable project mismatch')
    end
  end

  mount_uploader :attachment, AttachmentUploader

  # Scopes
  scope :for_commit_id, ->(commit_id) { where(noteable_type: "Commit", commit_id: commit_id) }
  scope :system, ->{ where(system: true) }
  scope :user, ->{ where(system: false) }
  scope :common, ->{ where(noteable_type: ["", nil]) }
  scope :fresh, ->{ order(created_at: :asc, id: :asc) }
  scope :inc_author_project, ->{ includes(:project, :author) }
  scope :inc_author, ->{ includes(:author) }
  scope :inc_relations_for_view, ->{ includes(:project, :author, :updated_by, :resolved_by, :award_emoji) }

  scope :discussion_notes, ->{ where(type: 'DiscussionNote') }
  scope :diff_notes, ->{ where(type: ['LegacyDiffNote', 'DiffNote']) }
  scope :non_diff_notes, ->{ where(type: ['Note', 'DiscussionNote', nil]) }

  scope :with_associations, -> do
    # FYI noteable cannot be loaded for LegacyDiffNote for commits
    includes(:author, :noteable, :updated_by,
             project: [:project_members, { group: [:group_members] }])
  end

  after_initialize :ensure_discussion_id
  before_validation :nullify_blank_type, :nullify_blank_line_code
  before_validation :set_discussion_id
  after_save :keep_around_commit, unless: :for_personal_snippet?

  class << self
    def model_name
      ActiveModel::Name.new(self, nil, 'note')
    end

    def resolvable?
      false
    end

    def discussions
      Discussion.build_collection(fresh)
    end

    def find_discussion(discussion_id)
      notes = where(discussion_id: discussion_id).fresh.to_a
      return if notes.empty?

      Discussion.build(notes)
    end

    def grouped_diff_discussions
      diff_notes.
        fresh.
        select(&:active?).
        group_by(&:line_code).
        map { |line_code, notes| [line_code, DiffDiscussion.build(notes)] }.
        to_h
    end

    def count_for_collection(ids, type)
      user.select('noteable_id', 'COUNT(*) as count').
        group(:noteable_id).
        where(noteable_type: type, noteable_id: ids)
    end
  end

  def cross_reference?
    system && SystemNoteService.cross_reference?(note)
  end

  def diff_note?
    false
  end

  def legacy_diff_note?
    false
  end

  def new_diff_note?
    false
  end

  def active?
    true
  end

  def part_of_discussion?
    false
  end

  def max_attachment_size
    current_application_settings.max_attachment_size.megabytes.to_i
  end

  def hook_attrs
    attributes
  end

  def for_commit?
    noteable_type == "Commit"
  end

  def for_issue?
    noteable_type == "Issue"
  end

  def for_merge_request?
    noteable_type == "MergeRequest"
  end

  def for_snippet?
    noteable_type == "Snippet"
  end

  def for_personal_snippet?
    noteable.is_a?(PersonalSnippet)
  end

  def skip_project_check?
    for_personal_snippet?
  end

  # override to return commits, which are not active record
  def noteable
    if for_commit?
      project.commit(commit_id)
    else
      super
    end
  # Temp fix to prevent app crash
  # if note commit id doesn't exist
  rescue
    nil
  end

  # FIXME: Hack for polymorphic associations with STI
  #        For more information visit http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#label-Polymorphic+Associations
  def noteable_type=(noteable_type)
    super(noteable_type.to_s.classify.constantize.base_class.to_s)
  end

  def editable?
    !system?
  end

  def cross_reference_not_visible_for?(user)
    cross_reference? && !has_referenced_mentionables?(user)
  end

  def has_referenced_mentionables?(user)
    if user_visible_reference_count.present?
      user_visible_reference_count > 0
    else
      referenced_mentionables(user).any?
    end
  end

  def award_emoji?
    can_be_award_emoji? && contains_emoji_only?
  end

  def emoji_awardable?
    !system?
  end

  def can_be_award_emoji?
    noteable.is_a?(Awardable) && !part_of_discussion?
  end

  def contains_emoji_only?
    note =~ /\A#{Banzai::Filter::EmojiFilter.emoji_pattern}\s?\Z/
  end

  def award_emoji_name
    note.match(Banzai::Filter::EmojiFilter.emoji_pattern)[1]
  end

  def to_ability_name
    for_personal_snippet? ? 'personal_snippet' : noteable_type.underscore
  end

  def discussion_class
    if for_commit?
      CommitDiscussion
    else
      SingleNoteDiscussion
    end
  end

  # Returns a discussion containing just this note
  def to_discussion
    Discussion.build([self])
  end

  # Returns the entire discussion this note is part of
  def discussion
    if part_of_discussion?
      self.noteable.notes.find_discussion(self.discussion_id)
    else
      to_discussion
    end
  end

  private

  def keep_around_commit
    project.repository.keep_around(self.commit_id)
  end

  def nullify_blank_type
    self.type = nil if self.type.blank?
  end

  def nullify_blank_line_code
    self.line_code = nil if self.line_code.blank?
  end

  def ensure_discussion_id
    return unless self.persisted?
    # Needed in case the SELECT statement doesn't ask for `discussion_id`
    return unless self.has_attribute?(:discussion_id)
    return if self.discussion_id

    set_discussion_id
    update_column(:discussion_id, self.discussion_id)
  end

  def set_discussion_id
    self.discussion_id = discussion_class.discussion_id(self)
  end
end
