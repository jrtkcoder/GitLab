require 'spec_helper'

describe Gitlab::ImportExport::RepoRestorer, services: true do
  let(:user) { create(:user) }
  let!(:project_with_repo) { create(:project, :test_repo, name: 'test-repo-restorer', path: 'test-repo-restorer') }
  let!(:project) { create(:empty_project) }
  let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let(:shared) { Gitlab::ImportExport::Shared.new(relative_path: project.path_with_namespace) }
  let(:bundler) { Gitlab::ImportExport::RepoSaver.new(project: project_with_repo, shared: shared) }
  let(:bundle_path) { File.join(shared.export_path, Gitlab::ImportExport.project_bundle_filename) }
  let(:restorer) do
    described_class.new(path_to_bundle: bundle_path,
                        shared: shared,
                        project: project)
  end

  describe 'bundle a project Git repo' do
    before do
      allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)

      bundler.save
    end

    after do
      FileUtils.rm_rf(export_path)
      FileUtils.rm_rf(project_with_repo.repository.path_to_repo)
      FileUtils.rm_rf(project.repository.path_to_repo)
    end

    it 'restores the repo successfully' do
      expect(restorer.restore).to be true
    end

    it 'has the webhooks' do
      restorer.restore

      expect(Gitlab::Git::Hook.new('post-receive', project.repository.path_to_repo)).to exist
    end
  end

  describe 'fork project with MRs' do
    let(:forked_from_project) { create(:project) }
    let(:fork_link) { create(:forked_project_link, forked_from_project: project_with_repo) }

    let!(:merge_request) do
      create(:merge_request, source_project: fork_link.forked_to_project,
             target_project: project_with_repo)
    end

    before do
      allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)

      # bundler.save && restorer.restore
    end

    it 'can access the MR' do
      expect(project.merge_requests.first.ensure_ref_fetched).not_to raise_error
    end
  end
end
