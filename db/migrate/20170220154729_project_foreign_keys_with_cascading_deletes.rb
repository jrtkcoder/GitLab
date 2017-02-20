# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ProjectForeignKeysWithCascadingDeletes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # The tables/columns for which to remove orphans and add foreign keys. Order
  # matters as some tables/columns should be processed before others.
  TABLES = [
    [:boards, :projects, :project_id],
    [:lists, :labels, :label_id],
    [:lists, :boards, :board_id],
    [:services, :projects, :project_id],
    [:forked_project_links, :projects, :forked_to_project_id],
    [:merge_requests, :projects, :target_project_id],
    [:labels, :projects, :project_id],
    [:issues, :projects, :project_id],
    [:events, :projects, :project_id],
    [:milestones, :projects, :project_id],
    [:notes, :projects, :project_id],
    [:snippets, :projects, :project_id],
    [:web_hooks, :projects, :project_id],
    [:protected_branch_merge_access_levels, :protected_branches, :protected_branch_id],
    [:protected_branches, :projects, :project_id],
    [:deploy_keys_projects, :projects, :project_id],
    [:users_star_projects, :projects, :project_id],
    [:releases, :projects, :project_id],
    [:project_group_links, :projects, :project_id],
    [:pages_domains, :projects, :project_id],
    [:todos, :projects, :project_id],
    [:project_import_data, :projects, :project_id],
    [:project_features, :projects, :project_id],
    [:project_statistics, :projects, :project_id],
    [:ci_builds, :projects, :gl_project_id],
    [:ci_commits, :projects, :gl_project_id],
    [:ci_runner_projects, :projects, :gl_project_id],
    [:ci_variables, :projects, :gl_project_id],
    [:ci_triggers, :projects, :gl_project_id],
    [:environments, :projects, :project_id],
    [:deployments, :projects, :project_id]
  ]

  def up
    # These existing foreign keys don't have an "ON DELETE CASCADE" clause.
    remove_foreign_key_without_error(:boards, :project_id)
    remove_foreign_key_without_error(:lists, :label_id)
    remove_foreign_key_without_error(:lists, :board_id)
    remove_foreign_key_without_error(:protected_branch_merge_access_levels,
                                     :protected_branch_id)

    remove_orphaned_rows(TABLES)

    TABLES.each do |(source, target, column)|
      add_concurrent_foreign_key(source, target, column: column)
    end
  end

  def down
    TABLES.each do |(source, target, column)|
      remove_foreign_key(source, name: "fk_#{source}_#{target}_#{column}")
    end

    add_concurrent_foreign_key(:boards, :projects, column: :project_id)
    add_concurrent_foreign_key(:lists, :labels, column: :label_id)
    add_concurrent_foreign_key(:lists, :boards, column: :board_id)
    add_concurrent_foreign_key(:protected_branch_merge_access_levels,
                               :protected_branches,
                               column: :protected_branch_id)
  end

  # Removes orphans from various tables concurrently.
  def remove_orphaned_rows(tuples)
    concurrency = 4

    Gitlab::Database.with_connection_pool(concurrency) do |pool|
      queues = Array.new(concurrency) { Queue.new }
      slice_size = tuples.length / concurrency

      # Divide all the tuples as evenly as possible amongst the queues.
      tuples.each_slice(slice_size).each_with_index do |slice, index|
        bucket = index % concurrency

        slice.each do |tuple|
          queues[bucket] << tuple
        end
      end

      # Consume all queues in a work-stealing fashion.
      threads = queues.map do |queue|
        Thread.new do
          pool.with_connection do |connection|
            Thread.current[:foreign_key_connection] = connection

            disable_statement_timeout

            remove_orphans(*queue.pop) until queue.empty?

            until queues.all?(&:empty?)
              queues.each do |inner_queue|
                next if inner_queue == queue

                # Stealing is racy so it's possible a pop might be called on an
                # already-empty queue.
                begin
                  remove_orphans(*inner_queue.pop(true))
                rescue ThreadError
                end
              end
            end
          end
        end
      end

      threads.each(&:join)
    end
  end

  def remove_orphans(source, target, column)
    quoted_source = quote_table_name(source)
    quoted_target = quote_table_name(target)
    quoted_column = quote_column_name(column)

    execute <<-EOF.strip_heredoc
    DELETE FROM #{quoted_source}
    WHERE NOT EXISTS (
      SELECT true
      FROM #{quoted_target}
      WHERE #{quoted_target}.id = #{quoted_source}.#{quoted_column}
    )
    EOF
  end

  def remove_foreign_key_without_error(table, column)
    remove_foreign_key(table, column: column)
  rescue ArgumentError
  end

  def connection
    # Rails memoizes connection objects, but this causes them to be shared
    # amongst threads; we don't want that.
    Thread.current[:foreign_key_connection] || ActiveRecord::Base.connection
  end
end
