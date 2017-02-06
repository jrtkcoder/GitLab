class MigrateBuildEventsToPipelineEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    slack_and_mattermost = spawn <<-SQL.strip_heredoc
      UPDATE services
        SET properties = replace(properties,
                                 'notify_only_broken_builds',
                                 'notify_only_broken_pipelines')
          , pipeline_events = #{true_value}
          , build_events = #{false_value}
      WHERE type IN ('SlackService', 'MattermostService', 'HipchatService')
        AND build_events = #{true_value};
    SQL

    builds_email = spawn <<-SQL.strip_heredoc
      UPDATE services
        SET type = 'PipelinesEmailService'
          , properties = replace(properties,
                                 'notify_only_broken_builds',
                                 'notify_only_broken_pipelines')
          , pipeline_events = #{true_value}
          , build_events = #{false_value}
      WHERE type = 'BuildsEmailService';

      DELETE FROM services WHERE type = 'BuildsEmailService';
    SQL

    [slack_and_mattermost, builds_email].each(&:join)
  end

  private

  def spawn(query)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::Base.connection.execute(query)
      end
    end
  end

  def quote(value)
    ActiveRecord::Base.connection.quote(value)
  end

  def true_value
    quote(true)
  end

  def false_value
    quote(false)
  end
end
