# TODO: Fix this terrible name
class DiscussionDiscussion < Discussion
  def self.build_discussion_id(note)
    [*super(note), SecureRandom.hex]
  end
end
