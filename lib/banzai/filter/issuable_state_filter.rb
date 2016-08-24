module Banzai
  module Filter
    # HTML filter that appends state information to issuable links.
    # Runs as a post-process filter as issuable state might change whilst
    # Markdown is in the cache.
    #
    # This filter supports cross-project references.
    class IssuableStateFilter < HTML::Pipeline::Filter
      QUERY = %q(
        descendant-or-self::a[contains(concat(" ", @class, " "), " gfm ")]
        [@data-reference-type="issue" or @data-reference-type="merge_request"]
      ).freeze

      def call
        nodes = doc.xpath(QUERY)
        return doc unless nodes.count > 0

        issue_parser = Banzai::ReferenceParser::IssueParser.new(project, current_user)
        mr_parser = Banzai::ReferenceParser::MergeRequestParser.new(project, current_user)

        issuables = issue_parser.issues_for_nodes(nodes)
        issuables = issuables.merge(mr_parser.merge_requests_for_nodes(nodes))

        issuables.each do |node, issuable|
          unless issuable.open?
            node.children.last.content += " [#{issuable.state}]"
          end
        end

        doc
      end

      private

      def current_user
        context[:current_user]
      end

      def project
        context[:project]
      end
    end
  end
end
