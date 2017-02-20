class DiscussionNote < Note
  validates :noteable_type, inclusion: { in: ['MergeRequest', 'Commit'] }

  def part_of_discussion?
    true
  end

  def discussion_class
    DiscussionDiscussion
  end

  private

  def set_discussion_id
    if in_reply_to_discussion_id
      self.discussion_id = in_reply_to_discussion_id
    else
      super
    end
  end
end
