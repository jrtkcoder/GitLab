# Finders::MergeRequest class
#
# Used to filter MergeRequests collections by set of params
#
# Arguments:
#   current_user - which user use
#   params:
#     scope: 'created-by-me' or 'assigned-to-me' or 'all'
#     state: 'open', 'closed', 'merged', or 'all'
#     group_id: integer
#     project_id: integer
#     milestone_id: integer
#     assignee_id: integer
#     search: string
#     label_name: string
#     sort: string
#     non_archived: boolean
#
class MergeRequestsFinder < IssuableFinder
  def klass
    MergeRequest
  end

  private

  def iid_pattern
    @iid_pattern ||= %r{\A[
      #{Regexp.escape(MergeRequest.reference_prefix)}
      #{Regexp.escape(Issue.reference_prefix)}
      ](?<iid>\d+)\z
    }x
  end
end
