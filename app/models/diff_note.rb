class DiffNote < Note
  include NoteOnDiff

  serialize :original_position, Gitlab::Diff::Position
  serialize :position, Gitlab::Diff::Position

  validates :original_position, presence: true
  validates :position, presence: true
  validates :diff_line, presence: true
  validates :line_code, presence: true, line_code: true
  validates :noteable_type, inclusion: { in: %w(Commit MergeRequest) }
  validate :positions_complete
  validate :verify_supported

  after_initialize :ensure_original_discussion_id
  before_validation :set_original_position, :update_position, on: :create
  before_validation :set_line_code, :set_original_discussion_id
  # We need to do this again, because it's already in `Note`, but is affected by
  # `update_position` and needs to run after that.
  before_validation :set_discussion_id
  after_save :keep_around_commits

  def new_diff_note?
    true
  end

  def discussion_class
    DiffDiscussion
  end

  def diff_attributes
    { position: position.to_json }
  end

  def position=(new_position)
    if new_position.is_a?(String)
      new_position = JSON.parse(new_position) rescue nil
    end

    if new_position.is_a?(Hash)
      new_position = new_position.with_indifferent_access
      new_position = Gitlab::Diff::Position.new(new_position)
    end

    super(new_position)
  end

  def diff_file
    @diff_file ||= self.original_position.diff_file(self.project.repository)
  end

  def diff_line
    @diff_line ||= diff_file.line_for_position(self.original_position) if diff_file
  end

  def for_line?(line)
    diff_file.position(line) == self.original_position
  end

  def original_line_code
    self.diff_file.line_code(self.diff_line)
  end

  def active?(diff_refs = nil)
    return false unless supported?
    return true if for_commit?

    diff_refs ||= noteable_diff_refs

    self.position.diff_refs == diff_refs
  end

  private

  def supported?
    for_commit? || self.noteable.has_complete_diff_refs?
  end

  def noteable_diff_refs
    if noteable.respond_to?(:diff_sha_refs)
      noteable.diff_sha_refs
    else
      noteable.diff_refs
    end
  end

  def set_original_position
    self.original_position = self.position.dup
  end

  def set_line_code
    self.line_code = self.position.line_code(self.project.repository)
  end

  def ensure_original_discussion_id
    return unless self.persisted?
    return if self.original_discussion_id

    set_original_discussion_id
    update_column(:original_discussion_id, self.original_discussion_id)
  end

  def set_original_discussion_id
    self.original_discussion_id = DiffDiscussion.original_discussion_id(self)
  end

  def update_position
    return unless supported?
    return if for_commit?

    return if active?

    Notes::DiffPositionUpdateService.new(
      self.project,
      nil,
      old_diff_refs: self.position.diff_refs,
      new_diff_refs: noteable_diff_refs,
      paths: self.position.paths
    ).execute(self)
  end

  def verify_supported
    return if supported?

    errors.add(:noteable, "doesn't support new-style diff notes")
  end

  def positions_complete
    return if self.original_position.complete? && self.position.complete?

    errors.add(:position, "is invalid")
  end

  def keep_around_commits
    project.repository.keep_around(self.original_position.base_sha)
    project.repository.keep_around(self.original_position.start_sha)
    project.repository.keep_around(self.original_position.head_sha)

    if self.position != self.original_position
      project.repository.keep_around(self.position.base_sha)
      project.repository.keep_around(self.position.start_sha)
      project.repository.keep_around(self.position.head_sha)
    end
  end
end
