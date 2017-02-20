# TODO: Notes should really have unique discussion IDs for various reasons, the excpetion being commit notes which we want to group together on the MR page. But if we want to support threading on the commit page, that doesn't cut it because they will still be grouped together and not in the right order
# So, either we don't support threaded notes on commits and _only_ in MRs. But I can see this being asked for issues too, where we may have the same issue.
# Really, the fact that all commit "root notes" should be grouped on the MR page is the weird part here. There should be a better way of figuring that out.
# I think we need to pass the noteable to the Notes.discussions scope so we can determine discussion_id on the fly based on context, and make all commit root notes have the same one.
# Alternatively, collect the commit notes manually, but this would create issues with all of the other infra that depends on discussion_id, like the JS

class CommitDiscussion < Discussion
  def potentially_resolvable?
    false
  end

  def render_as_individual_notes?(target)
    target == self.noteable
  end
end
