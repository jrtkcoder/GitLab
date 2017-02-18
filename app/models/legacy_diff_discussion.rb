class LegacyDiffDiscussion < DiffDiscussion

  def self.unique_position_identifier(note)
    note.line_code
  end

  def legacy_diff_discussion?
    true
  end

  def potentially_resolvable?
    false
  end

  def collapsed?
    !active?
  end
end
