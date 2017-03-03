require 'spec_helper'

describe Ci::ProcessPipelineService, '#execute', :services do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }

  let(:pipeline) do
    create(:ci_empty_pipeline, ref: 'master', project: project)
  end

  before do
    project.add_developer(user)
  end

  context 'when simple pipeline is defined' do
    before do
      create_build('linux', stage_idx: 0)
      create_build('mac', stage_idx: 0)
      create_build('rspec', stage_idx: 1)
      create_build('rubocop', stage_idx: 1)
      create_build('deploy', stage_idx: 2)
    end

    it 'processes a pipeline' do
      expect(process_pipeline).to be_truthy

      succeed_pending

      expect(builds.success.count).to eq(2)
      expect(process_pipeline).to be_truthy

      succeed_pending

      expect(builds.success.count).to eq(4)
      expect(process_pipeline).to be_truthy

      succeed_pending

      expect(builds.success.count).to eq(5)
      expect(process_pipeline).to be_falsey
    end

    it 'does not process pipeline if existing stage is running' do
      expect(process_pipeline).to be_truthy
      expect(builds.pending.count).to eq(2)

      expect(process_pipeline).to be_falsey
      expect(builds.pending.count).to eq(2)
    end
  end

  context 'custom stage with first job allowed to fail' do
    before do
      create_build('clean_job', stage_idx: 0, allow_failure: true)
      create_build('test_job', stage_idx: 1, allow_failure: true)
    end

    it 'automatically triggers a next stage when build finishes' do
      expect(process_pipeline).to be_truthy
      expect(builds_statuses).to eq ['pending']

      fail_running_or_pending

      expect(builds_statuses).to eq %w(failed pending)
    end
  end

  context 'when optional manual actions are defined' do
    before do
      create_build('build', stage_idx: 0)
      create_build('test', stage_idx: 1)
      create_build('test_failure', stage_idx: 2, when: 'on_failure')
      create_build('deploy', stage_idx: 3)
      create_build('production', stage_idx: 3, when: 'manual', allow_failure: true)
      create_build('cleanup', stage_idx: 4, when: 'always')
      create_build('clear cache', stage_idx: 4, when: 'manual', allow_failure: true)
    end

    context 'when builds are successful' do
      it 'properly processes the pipeline' do
        expect(process_pipeline).to be_truthy
        expect(builds_names).to eq ['build']
        expect(builds_statuses).to eq ['pending']

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test)
        expect(builds_statuses).to eq %w(success pending)

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test deploy)
        expect(builds_statuses).to eq %w(success success pending)

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test deploy cleanup)
        expect(builds_statuses).to eq %w(success success success pending)

        succeed_running_or_pending

        expect(builds_statuses).to eq %w(success success success success)
        expect(pipeline.reload.status).to eq 'success'
      end
    end

    context 'when test job fails' do
      it 'properly processes the pipeline' do
        expect(process_pipeline).to be_truthy
        expect(builds_names).to eq ['build']
        expect(builds_statuses).to eq ['pending']

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test)
        expect(builds_statuses).to eq %w(success pending)

        fail_running_or_pending

        expect(builds_names).to eq %w(build test test_failure)
        expect(builds_statuses).to eq %w(success failed pending)

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test test_failure cleanup)
        expect(builds_statuses).to eq %w(success failed success pending)

        succeed_running_or_pending

        expect(builds_statuses).to eq %w(success failed success success)
        expect(pipeline.reload.status).to eq 'failed'
      end
    end

    context 'when test and test_failure jobs fail' do
      it 'properly processes the pipeline' do
        expect(process_pipeline).to be_truthy
        expect(builds_names).to eq ['build']
        expect(builds_statuses).to eq ['pending']

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test)
        expect(builds_statuses).to eq %w(success pending)

        fail_running_or_pending

        expect(builds_names).to eq %w(build test test_failure)
        expect(builds_statuses).to eq %w(success failed pending)

        fail_running_or_pending

        expect(builds_names).to eq %w(build test test_failure cleanup)
        expect(builds_statuses).to eq %w(success failed failed pending)

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test test_failure cleanup)
        expect(builds_statuses).to eq %w(success failed failed success)
        expect(pipeline.reload.status).to eq('failed')
      end
    end

    context 'when deploy job fails' do
      it 'properly processes the pipeline' do
        expect(process_pipeline).to be_truthy
        expect(builds_names).to eq ['build']
        expect(builds_statuses).to eq ['pending']

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test)
        expect(builds_statuses).to eq %w(success pending)

        succeed_running_or_pending

        expect(builds_names).to eq %w(build test deploy)
        expect(builds_statuses).to eq %w(success success pending)

        fail_running_or_pending

        expect(builds_names).to eq %w(build test deploy cleanup)
        expect(builds_statuses).to eq %w(success success failed pending)

        succeed_running_or_pending

        expect(builds_statuses).to eq %w(success success failed success)
        expect(pipeline.reload.status).to eq('failed')
      end
    end

    context 'when build is canceled in the second stage' do
      it 'does not schedule builds after build has been canceled' do
        expect(process_pipeline).to be_truthy
        expect(builds_names).to eq ['build']
        expect(builds_statuses).to eq ['pending']

        succeed_running_or_pending

        expect(builds.running_or_pending).not_to be_empty
        expect(builds_names).to eq %w(build test)
        expect(builds_statuses).to eq %w(success pending)

        cancel_running_or_pending

        expect(builds.running_or_pending).to be_empty
        expect(pipeline.reload.status).to eq 'canceled'
      end
    end

    context 'when listing optional manual actions' do
      it 'returns only for skipped builds' do
        # currently all builds are created
        expect(process_pipeline).to be_truthy
        expect(manual_actions).to be_empty

        # succeed stage build
        succeed_running_or_pending

        expect(manual_actions).to be_empty

        # succeed stage test
        succeed_running_or_pending

        expect(manual_actions).to be_one # production

        # succeed stage deploy
        succeed_running_or_pending

        expect(manual_actions).to be_many # production and clear cache
      end
    end
  end

  context 'when there are manual action in earlier stages' do
    context 'when first stage has only optional manual actions' do
      before do
        create_build('build', stage_idx: 0, when: 'manual', allow_failure: true)
        create_build('check', stage_idx: 1)
        create_build('test', stage_idx: 2)

        process_pipeline
      end

      it 'starts from the second stage' do
        expect(all_builds_statuses).to eq %w[skipped pending created]
      end
    end

    context 'when second stage has only optional manual actions' do
      before do
        create_build('check', stage_idx: 0)
        create_build('build', stage_idx: 1, when: 'manual', allow_failure: true)
        create_build('test', stage_idx: 2)

        process_pipeline
      end

      it 'skips second stage and continues on third stage' do
        expect(all_builds_statuses).to eq(%w[pending created created])

        builds.first.success

        expect(all_builds_statuses).to eq(%w[success skipped pending])
      end
    end
  end

  context 'when blocking manual actions are defined' do
    before do
      create_build('code:test', stage_idx: 0)
      create_build('staging:deploy', stage_idx: 1, when: 'manual')
      create_build('staging:test', stage_idx: 2, when: 'on_success')
      create_build('production:deploy', stage_idx: 3, when: 'manual')
      create_build('production:test', stage_idx: 4, when: 'always')
    end

    it 'blocks pipeline on stage with first manual action' do
      process_pipeline

      expect(builds_names).to eq %w[code:test]
      expect(builds_statuses).to eq %w[pending]
      expect(pipeline.reload.status).to eq 'pending'

      succeed_running_or_pending

      expect(builds_names).to eq %w[code:test staging:deploy]
      expect(builds_statuses).to eq %w[success manual]
      expect(pipeline.reload).to be_manual
    end
  end

  context 'when second stage has only on_failure jobs' do
    before do
      create_build('check', stage_idx: 0)
      create_build('build', stage_idx: 1, when: 'on_failure')
      create_build('test', stage_idx: 2)

      process_pipeline
    end

    it 'skips second stage and continues on third stage' do
      expect(all_builds_statuses).to eq(%w[pending created created])

      builds.first.success

      expect(all_builds_statuses).to eq(%w[success skipped pending])
    end
  end

  context 'when failed build in the middle stage is retried' do
    context 'when failed build is the only unsuccessful build in the stage' do
      before do
        create_build('build:1', stage_idx: 0)
        create_build('build:2', stage_idx: 0)
        create_build('test:1', stage_idx: 1)
        create_build('test:2', stage_idx: 1)
        create_build('deploy:1', stage_idx: 2)
        create_build('deploy:2', stage_idx: 2)
      end

      it 'does trigger builds in the next stage' do
        expect(process_pipeline).to be_truthy
        expect(builds_names).to eq ['build:1', 'build:2']

        succeed_running_or_pending

        expect(builds_names).to eq ['build:1', 'build:2', 'test:1', 'test:2']

        pipeline.builds.find_by(name: 'test:1').success
        pipeline.builds.find_by(name: 'test:2').drop

        expect(builds_names).to eq ['build:1', 'build:2', 'test:1', 'test:2']

        Ci::Build.retry(pipeline.builds.find_by(name: 'test:2'), user).success

        expect(builds_names).to eq ['build:1', 'build:2', 'test:1', 'test:2',
                                    'test:2', 'deploy:1', 'deploy:2']
      end
    end
  end

  context 'when there are builds that are not created yet' do
    let(:pipeline) do
      create(:ci_pipeline, config: config)
    end

    let(:config) do
      { rspec: { stage: 'test', script: 'rspec' },
        deploy: { stage: 'deploy', script: 'rsync' } }
    end

    before do
      create_build('linux', stage: 'build', stage_idx: 0)
      create_build('mac', stage: 'build', stage_idx: 0)
    end

    it 'processes the pipeline' do
      # Currently we have five builds with state created
      #
      expect(builds.count).to eq(0)
      expect(all_builds.count).to eq(2)

      # Process builds service will enqueue builds from the first stage.
      #
      process_pipeline

      expect(builds.count).to eq(2)
      expect(all_builds.count).to eq(2)

      # When builds succeed we will enqueue remaining builds.
      #
      # We will have 2 succeeded, 1 pending (from stage test), total 4 (two
      # additional build from `.gitlab-ci.yml`).
      #
      succeed_pending
      process_pipeline

      expect(builds.success.count).to eq(2)
      expect(builds.pending.count).to eq(1)
      expect(all_builds.count).to eq(4)

      # When pending merge_when_pipeline_succeeds in stage test, we enqueue deploy stage.
      #
      succeed_pending
      process_pipeline

      expect(builds.pending.count).to eq(1)
      expect(builds.success.count).to eq(3)
      expect(all_builds.count).to eq(4)

      # When the last one succeeds we have 4 successful builds.
      #
      succeed_pending
      process_pipeline

      expect(builds.success.count).to eq(4)
      expect(all_builds.count).to eq(4)
    end
  end

  def process_pipeline
    described_class.new(pipeline.project, user).execute(pipeline)
  end

  def all_builds
    pipeline.builds.order(:stage_idx, :id)
  end

  def builds
    all_builds.where.not(status: [:created, :skipped])
  end

  def builds_names
    builds.pluck(:name)
  end

  def builds_statuses
    builds.pluck(:status)
  end

  def all_builds_statuses
    all_builds.pluck(:status)
  end

  def succeed_pending
    builds.pending.update_all(status: 'success')
  end

  def succeed_running_or_pending
    pipeline.builds.running_or_pending.each(&:success)
  end

  def fail_running_or_pending
    pipeline.builds.running_or_pending.each(&:drop)
  end

  def cancel_running_or_pending
    pipeline.builds.running_or_pending.each(&:cancel)
  end

  delegate :manual_actions, to: :pipeline

  def create_build(name, **opts)
    create(:ci_build, :created, pipeline: pipeline, name: name, **opts)
  end
end
