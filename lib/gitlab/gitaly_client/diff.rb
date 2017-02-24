module Gitlab
  module GitalyClient
    class Diff
      # The maximum size of a diff to display.
      DIFF_SIZE_LIMIT = 102400 # 100 KB

      # The maximum size before a diff is collapsed.
      DIFF_COLLAPSE_LIMIT = 10240 # 10 KB

      BLANK_SHA = ("0" * 40).freeze

      attr_reader :diff_msg

      def initialize(diff_msg)
        @diff_msg = diff_msg
      end

      def diff
        collapsed? ? "" : diff_msg.raw_chunks.join
      end

      # TODO: Rename to_path to new_path in proto definition
      def new_path
        diff_msg.to_path.dup
      end

      # TODO: Rename from_path to old_path in proto definition
      def old_path
        diff_msg.from_path.dup
      end

      # TODO: Consider returning status in RPC response
      def deleted_file?
        diff_msg.to_id == BLANK_SHA
      end
      alias_method :deleted_file, :deleted_file?

      def renamed_file?
        diff_msg.from_path != diff_msg.to_path
      end
      alias_method :renamed_file, :renamed_file?

      def new_file?
        diff_msg.from_id == BLANK_SHA
      end
      alias_method :new_file, :new_file?

      def a_mode
        diff_msg.old_mode.to_s(8)
      end

      def b_mode
        diff_msg.new_mode.to_s(8)
      end

      def too_large?
        chunks_size >= DIFF_SIZE_LIMIT
      end

      def collapsed?
        return @collapsed if defined?(@collapsed)
        collapse_if_eligible
      end

      def submodule?
        a_mode == '160000' || b_mode == '160000'
      end

      private

      def collapse_if_eligible
        @collapsed = chunks_size >= DIFF_COLLAPSE_LIMIT
      end

      def chunks_size
        @chunks_size ||= diff_msg.raw_chunks.sum(&:bytesize)
      end
    end
  end
end

