module API
  module V3
    module Entities
      class ProjectSnippet < Grape::Entity
        expose :id, :title, :file_name
        expose :author, using: ::API::Entities::UserBasic
        expose :updated_at, :created_at
        expose(:expires_at) { |snippet| nil }

        expose :web_url do |snippet, options|
          Gitlab::UrlBuilder.build(snippet)
        end
      end

      class Note < Grape::Entity
        expose :id
        expose :note, as: :body
        expose :attachment_identifier, as: :attachment
        expose :author, using: ::API::Entities::UserBasic
        expose :created_at, :updated_at
        expose :system?, as: :system
        expose :noteable_id, :noteable_type
        # upvote? and downvote? are deprecated, always return false
        expose(:upvote?)    { |note| false }
        expose(:downvote?)  { |note| false }
      end

      class Event < Grape::Entity
        expose :title, :project_id, :action_name
        expose :target_id, :target_type, :author_id
        expose :data, :target_title
        expose :created_at
        expose :note, using: Entities::Note, if: ->(event, options) { event.note? }
        expose :author, using: ::API::Entities::UserBasic, if: ->(event, options) { event.author }

        expose :author_username do |event, options|
          event.author&.username
        end
      end

      class AwardEmoji < Grape::Entity
        expose :id
        expose :name
        expose :user, using: ::API::Entities::UserBasic
        expose :created_at, :updated_at
        expose :awardable_id, :awardable_type
      end

      class Project < Grape::Entity
        expose :id, :description, :default_branch, :tag_list
        expose :public?, as: :public
        expose :archived?, as: :archived
        expose :visibility_level, :ssh_url_to_repo, :http_url_to_repo, :web_url
        expose :owner, using: ::API::Entities::UserBasic, unless: ->(project, options) { project.group }
        expose :name, :name_with_namespace
        expose :path, :path_with_namespace
        expose :container_registry_enabled

        # Expose old field names with the new permissions methods to keep API compatible
        expose(:issues_enabled) { |project, options| project.feature_available?(:issues, options[:current_user]) }
        expose(:merge_requests_enabled) { |project, options| project.feature_available?(:merge_requests, options[:current_user]) }
        expose(:wiki_enabled) { |project, options| project.feature_available?(:wiki, options[:current_user]) }
        expose(:builds_enabled) { |project, options| project.feature_available?(:builds, options[:current_user]) }
        expose(:snippets_enabled) { |project, options| project.feature_available?(:snippets, options[:current_user]) }

        expose :created_at, :last_activity_at
        expose :shared_runners_enabled
        expose :lfs_enabled?, as: :lfs_enabled
        expose :creator_id
        expose :namespace, using: 'API::Entities::Namespace'
        expose :forked_from_project, using: ::API::Entities::BasicProjectDetails, if: lambda{ |project, options| project.forked? }
        expose :avatar_url
        expose :star_count, :forks_count
        expose :open_issues_count, if: lambda { |project, options| project.feature_available?(:issues, options[:current_user]) && project.default_issues_tracker? }
        expose :runners_token, if: lambda { |_project, options| options[:user_can_admin_project] }
        expose :public_builds
        expose :shared_with_groups do |project, options|
          ::API::Entities::SharedGroup.represent(project.project_group_links.all, options)
        end
        expose :only_allow_merge_if_pipeline_succeeds, as: :only_allow_merge_if_build_succeeds
        expose :request_access_enabled
        expose :only_allow_merge_if_all_discussions_are_resolved

        expose :statistics, using: 'API::Entities::ProjectStatistics', if: :statistics
      end

      class MergeRequest < Grape::Entity
        expose :id, :iid
        expose(:project_id) { |entity| entity.project.id }
        expose :title, :description
        expose :state, :created_at, :updated_at
        expose :target_branch, :source_branch
        expose :upvotes, :downvotes
        expose :author, :assignee, using: ::API::Entities::UserBasic
        expose :source_project_id, :target_project_id
        expose :label_names, as: :labels
        expose :work_in_progress?, as: :work_in_progress
        expose :milestone, using: ::API::Entities::Milestone
        expose :merge_when_pipeline_succeeds, as: :merge_when_build_succeeds
        expose :merge_status
        expose :diff_head_sha, as: :sha
        expose :merge_commit_sha
        expose :subscribed do |merge_request, options|
          merge_request.subscribed?(options[:current_user], options[:project])
        end
        expose :user_notes_count
        expose :should_remove_source_branch?, as: :should_remove_source_branch
        expose :force_remove_source_branch?, as: :force_remove_source_branch

        expose :web_url do |merge_request, options|
          Gitlab::UrlBuilder.build(merge_request)
        end
      end
    end
  end
end
