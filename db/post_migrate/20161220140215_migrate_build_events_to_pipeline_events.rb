class MigrateBuildEventsToPipelineEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute <<-SQL.strip_heredoc
      DELETE FROM services
        WHERE type = 'BuildsEmailService'
          AND active = #{false_value}
          AND properties = '{"notify_only_broken_builds":true}';

      DELETE FROM services
        WHERE type = 'PipelinesEmailService'
          AND active = #{false_value}
          AND properties = '{"notify_only_broken_pipelines":true}';

      UPDATE services
        SET properties = replace(properties,
                                 'notify_only_broken_builds',
                                 'notify_only_broken_pipelines')
          , pipeline_events = #{true_value}
          , build_events = #{false_value}
      WHERE type IN ('SlackService', 'MattermostService')
        AND build_events = #{true_value};

      UPDATE services
        SET type = 'PipelinesEmailService'
          , properties = replace(properties,
                                 'notify_only_broken_builds',
                                 'notify_only_broken_pipelines')
          , pipeline_events = #{true_value}
          , build_events = #{false_value}
      WHERE type = 'BuildsEmailService';
    SQL
  end

  def true_value
    quote(true)
  end

  def false_value
    quote(false)
  end

  def quote(value)
    ActiveRecord::Base.connection.quote(value)
  end
end
