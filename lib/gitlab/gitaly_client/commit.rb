module Gitlab
  module GitalyClient
    class Commit
      class << self
        def diff_from_parent(commit, options = {})
          stub      = Gitaly::Diff::Stub.new(nil, nil, channel_override: GitalyClient.channel)
          repo      = Gitaly::Repository.new(path: commit.project.repository.path_to_repo)
          parent    = commit.parents[0]
          # The ID of empty tree.
          # See http://stackoverflow.com/a/40884093/1856239 and https://github.com/git/git/blob/3ad8b5bf26362ac67c9020bf8c30eee54a84f56d/cache.h#L1011-L1012
          parent_id = parent ? parent.id : '4b825dc642cb6eb9a060e54bf8d69288fbee4904'
          request   = Gitaly::CommitDiffRequest.new(
            repository: repo,
            left_commit_id: parent_id,
            right_commit_id: commit.id
          )

          GitalyClient::DiffCollection.new(stub.commit_diff(request, options).to_a)
        rescue GRPC::BadStatus => e
          raise e # XXX What to do?
        end
      end
    end
  end
end
