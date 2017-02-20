class SingleNoteDiscussion < Discussion
  def self.build_discussion_id(note)
    [*super(note), SecureRandom.hex]
  end

  def potentially_resolvable?
    false
  end

  def render_as_individual_notes?(target)
    true
  end
end
