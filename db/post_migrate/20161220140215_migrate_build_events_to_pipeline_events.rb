class MigrateBuildEventsToPipelineEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database

  DOWNTIME = false

  def up
    Gitlab::Database.with_connection_pool(2) do |pool|
      threads = []

      threads << Thread.new do
        pool.with_connection do |connection|
          connection.execute(<<-SQL.strip_heredoc)
            UPDATE services
              SET properties = replace(properties,
                                       'notify_only_broken_builds',
                                       'notify_only_broken_pipelines')
                , pipeline_events = #{true_value}
                , build_events = #{false_value}
            WHERE type IN
              ('SlackService', 'MattermostService', 'HipchatService')
              AND build_events = #{true_value};
          SQL
        end
      end

      threads << Thread.new do
        pool.with_connection do |connection|
          connection.execute(<<-SQL.strip_heredoc)
            UPDATE services
              SET type = 'PipelinesEmailService'
                , properties = replace(properties,
                                       'notify_only_broken_builds',
                                       'notify_only_broken_pipelines')
                , pipeline_events = #{true_value}
                , build_events = #{false_value}
            WHERE type = 'BuildsEmailService';
          SQL

          connection.execute(<<-SQL.strip_heredoc)
            DELETE FROM services WHERE type = 'BuildsEmailService';
          SQL
        end
      end

      threads.each(&:join)
    end
  end
end
