module Gitlab
  module GitalyClient
    class Ref
      class Enumerator
        include Enumerable

        def initialize(prefix, response)
          @prefix = prefix
          @response = response
        end

        def each
          return enum_for(:each) unless block_given?

          @response.each do |r|
            r.names.each { |name| yield name.gsub(/^#{@prefix}/, '') }
          end
        end

        # NOTE: Serialization methods are required because of `cache_method` in `Repository`.

        # For serializing, we load all ref names in an Array
        def marshal_dump
          { prefix: @prefix, names: to_a }
        end

        # Take the serialized refs array and load it into an `OpenStruct` so that
        # `each` works seamlessly
        def marshal_load(values)
          @prefix = values[:prefix]
          @response = [OpenStruct.new(names: values[:names])]
        end
      end

      attr_accessor :stub

      def initialize(repo_path)
        @stub = Gitaly::Ref::Stub.new(nil, nil, channel_override: GitalyClient.channel)
        @repository = Gitaly::Repository.new(path: repo_path)
      end

      def default_branch_name
        request = Gitaly::FindDefaultBranchNameRequest.new(repository: @repository)
        stub.find_default_branch_name(request).name.gsub(/^refs\/heads\//, '')
      end

      def branch_names
        request = Gitaly::FindAllBranchNamesRequest.new(repository: @repository)
        Enumerator.new('refs/heads/', stub.find_all_branch_names(request))
      end

      def tag_names
        request = Gitaly::FindAllTagNamesRequest.new(repository: @repository)
        Enumerator.new('refs/tags/', stub.find_all_tag_names(request))
      end
    end
  end
end
