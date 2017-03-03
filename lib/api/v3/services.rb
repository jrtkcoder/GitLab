module API
  module V3
    class Services < Grape::API
      services = %w[
        asana
        assembla
        bamboo
        bugzilla
        buildkite
        builds-email
        campfire
        custom-issue-tracker
        drone-ci
        emails-on-push
        external-wiki
        flowdock
        gemnasium
        hipchat
        irker
        jira
        kubernetes
        mattermost-slash-commands
        slack-slash-commands
        pipelines-email
        pivotaltracker
        pushover
        redmine
        slack
        mattermost
        teamcity
      ]

      resource :projects do
        before { authenticate! }
        before { authorize_admin_project }

        helpers do
          def service_attributes(service)
            service.fields.inject([]) do |arr, hash|
              arr << hash[:name].to_sym
            end
          end

          def service_slug
            params[:service_slug].underscore
              .sub(/\Abuild\-emails\z/, 'pipeline-emails')
          end
        end

        desc "Delete a service for project"
        params do
          requires :service_slug, type: String, values: services, desc: 'The name of the service'
        end
        delete ":id/services/:service_slug" do
          service = user_project.find_or_initialize_service(service_slug)

          attrs = service_attributes(service).inject({}) do |hash, key|
            hash.merge!(key => nil)
          end

          if service.update_attributes(attrs.merge(active: false))
            status(200)
            true
          else
            render_api_error!('400 Bad Request', 400)
          end
        end

        desc 'Get the service settings for project' do
          success ::API::Entities::ProjectService
        end
        params do
          requires :service_slug, type: String, values: services, desc: 'The name of the service'
        end
        get ":id/services/:service_slug" do
          service = user_project.find_or_initialize_service(service_slug)
          present service, with: ::API::Entities::ProjectService, include_passwords: current_user.is_admin?
        end

        #
        # Legacy builds-email implemented with pipelines-email below
        #

        desc 'Set pipelines-email service for project'
        params do
          requires :recipients,
            type: String,
            desc: 'Comma-separated list of recipient email addresses'

          optional :add_pusher,
            type: Boolean,
            desc: 'Legacy option. No effect now'

          optional :notify_only_broken_builds,
            type: Boolean,
            desc: 'Notify only broken pipelines'
        end
        put ':id/services/builds-email' do
          service = user_project.find_or_initialize_service('builds-email')
          service_params = declared_params(include_missing: false).merge(active: true)
          service_params.delete(:add_pusher)
          only_broken = service_params.delete(:notify_only_broken_builds)
          service_params[:notify_only_broken_pipelines] = only_broken

          if service.update(service_params)
            present service, with: ::API::Entities::ProjectService, include_passwords: current_user.is_admin?
          else
            render_api_error!('400 Bad Request', 400)
          end
        end
      end
    end
  end
end
