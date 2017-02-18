class SingleNoteDiscussion < Discussion
  def self.build_discussion_id(note)
    [*super(note), SecureRandom.hex]
  end

  def potentially_resolvable?
    false
  end

  def single_note?(target)
    true
  end
end
