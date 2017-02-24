module Gitlab
  module GitalyClient
    class DiffCollection
      include Enumerable

      DEFAULT_LIMITS = { max_files: 100, max_lines: 5000 }.freeze

      def initialize(diff_response, options = {})
        @diff_response = diff_response
        @diffs         = nil
        @decorated     = false
        @max_files     = options.fetch(:max_files, DEFAULT_LIMITS[:max_files])
        @all_diffs     = !!options.fetch(:all_diffs, false)
        @overflow      = !@all_diffs && size >= @max_files
      end

      def decorate!
        return if @decorated

        each_with_index do |diff, i|
          @diffs[i] = yield diff
        end

        @decorated = true

        self
      end

      def size
        @diff_response.size
      end

      def each(&block)
        if @diffs
          @diffs.each(&block)
        else
          each_diff(&block)
        end
      end

      def overflow?
        @overflow
      end

      private

      def each_diff
        @diffs ||= []

        @diff_response.each_with_index do |diff_msg, i|
          diff = GitalyClient::Diff.new(diff_msg)

          yield @diffs[i] = diff
        end
      end
    end
  end
end
