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

      class Build < Grape::Entity
        expose :id, :status, :stage, :name, :ref, :tag, :coverage
        expose :created_at, :started_at, :finished_at
        expose :user, with: ::API::Entities::User
        expose :artifacts_file, using: ::API::Entities::JobArtifactFile, if: -> (build, opts) { build.artifacts? }
        expose :commit, with: ::API::Entities::RepoCommit
        expose :runner, with: ::API::Entities::Runner
        expose :pipeline, with: ::API::Entities::PipelineBasic
      end

      class BuildArtifactFile < Grape::Entity
        expose :filename, :size
      end

      class EnvironmentBasic < Grape::Entity
        expose :id, :name, :slug, :external_url
      end

      class Environment < EnvironmentBasic
        expose :project, using: Entities::Project
      end

      class Deployment < Grape::Entity
        expose :id, :iid, :ref, :sha, :created_at
        expose :user,        using: Entities::UserBasic
        expose :environment, using: Entities::EnvironmentBasic
        expose :deployable,  using: Entities::Build
      end

      class Group < Grape::Entity
        expose :id, :name, :path, :description, :visibility_level
        expose :lfs_enabled?, as: :lfs_enabled
        expose :avatar_url
        expose :web_url
        expose :request_access_enabled
        expose :statistics, if: :statistics do
          with_options format_with: -> (value) { value.to_i } do
            expose :storage_size
            expose :repository_size
            expose :lfs_objects_size
            expose :build_artifacts_size
          end
        end
      end

      class GroupDetail < Group
        expose :projects, using: Entities::Project
        expose :shared_projects, using: Entities::Project
      end

      class MergeRequest < ProjectEntity
        expose :target_branch, :source_branch
        expose :upvotes, :downvotes
        expose :author, :assignee, using: Entities::UserBasic
        expose :source_project_id, :target_project_id
        expose :label_names, as: :labels
        expose :work_in_progress?, as: :work_in_progress
        expose :milestone, using: Entities::Milestone
        expose :merge_when_build_succeeds
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

      class MergeRequestChanges < MergeRequest
        expose :diffs, as: :changes, using: Entities::RepoDiff do |compare, _|
          compare.raw_diffs(all_diffs: true).to_a
        end
      end

      class Project < Grape::Entity
        expose :id, :description, :default_branch, :tag_list
        expose :public?, as: :public
        expose :archived?, as: :archived
        expose :visibility_level, :ssh_url_to_repo, :http_url_to_repo, :web_url
        expose :owner, using: Entities::UserBasic, unless: ->(project, options) { project.group }
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
        expose :forked_from_project, using: Entities::BasicProjectDetails, if: lambda{ |project, options| project.forked? }
        expose :avatar_url
        expose :star_count, :forks_count
        expose :open_issues_count, if: lambda { |project, options| project.feature_available?(:issues, options[:current_user]) && project.default_issues_tracker? }
        expose :runners_token, if: lambda { |_project, options| options[:user_can_admin_project] }
        expose :public_builds
        expose :shared_with_groups do |project, options|
          SharedGroup.represent(project.project_group_links.all, options)
        end
        expose :only_allow_merge_if_build_succeeds
        expose :request_access_enabled
        expose :only_allow_merge_if_all_discussions_are_resolved
        expose :statistics, using: 'API::Entities::ProjectStatistics', if: :statistics
      end

      class ProjectStatistics < Grape::Entity
        expose :commit_count
        expose :storage_size
        expose :repository_size
        expose :lfs_objects_size
        expose :build_artifacts_size
      end

      class ProjectService < Grape::Entity
        expose :id, :title, :created_at, :updated_at, :active
        expose :push_events, :issues_events, :merge_requests_events
        expose :tag_push_events, :note_events, :build_events, :pipeline_events
        # Expose serialized properties
        expose :properties do |service, options|
          field_names = service.fields.
            select { |field| options[:include_passwords] || field[:type] != 'password' }.
            map { |field| field[:name] }
          service.properties.slice(*field_names)
        end
      end

      class ProjectHook < Hook
        expose :project_id, :issues_events, :merge_requests_events
        expose :note_events, :build_events, :pipeline_events, :wiki_page_events
      end

      class ProjectWithAccess < Project
        expose :permissions do
          expose :project_access, using: Entities::ProjectAccess do |project, options|
            project.project_members.find_by(user_id: options[:current_user].id)
          end
          expose :group_access, using: Entities::GroupAccess do |project, options|
            if project.group
              project.group.group_members.find_by(user_id: options[:current_user].id)
            end
          end
        end
      end
    end
  end
end
