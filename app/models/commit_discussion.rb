class CommitDiscussion < Discussion
  def potentially_resolvable?
    false
  end

  def single_note?(target)
    target == self.noteable
  end
end
