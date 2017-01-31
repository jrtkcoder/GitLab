module Projects
  module Settings
    class DeployKeysPresenter < Gitlab::View::Presenter::Simple
      presents :project

      def new_key
        @key ||= DeployKey.new
      end

      def enabled_keys
        @enabled_keys ||= project.deploy_keys
      end

      def any_keys_enabled?
        enabled_keys.any?
      end

      def enabled_keys_size
        enabled_keys.size
      end

      def available_keys
        @available_keys ||= current_user.accessible_deploy_keys - enabled_keys
      end

      def available_project_keys
        @available_project_keys ||= current_user.project_deploy_keys - enabled_keys
      end

      def any_available_project_keys_enabled?
        available_project_keys.any?
      end

      def available_project_keys_size
        available_project_keys.size
      end

      def available_public_keys
        return @available_public_keys if defined?(@available_public_keys)

        @available_public_keys ||= DeployKey.are_public - enabled_keys

        # Public keys that are already used by another accessible project are already
        # in @available_project_keys.
        @available_public_keys -= available_project_keys
      end

      def any_available_public_keys_enabled?
        available_public_keys.any?
      end

      def available_public_keys_size
        available_public_keys.size
      end

      def to_partial_path
        'projects/deploy_keys/index'
      end

      def form_partial_path
        'projects/deploy_keys/form'
      end
    end
  end
end
