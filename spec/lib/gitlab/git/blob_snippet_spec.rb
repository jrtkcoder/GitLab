# encoding: UTF-8

require "gitlab_git_spec_helper"

describe Gitlab::Git::BlobSnippet do
  describe :data do
    context 'empty lines' do
      let(:snippet) { Gitlab::Git::BlobSnippet.new('master', nil, nil, nil) }

      it { expect(snippet.data).to be_nil }
    end

    context 'present lines' do
      let(:snippet) { Gitlab::Git::BlobSnippet.new('master', ['wow', 'much'], 1, 'wow.rb') }

      it { expect(snippet.data).to eq("wow\nmuch") }
    end
  end
end