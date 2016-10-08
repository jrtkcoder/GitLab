require 'spec_helper'

describe IssueTrackerService, models: true do
  describe 'Validations' do
    let(:project) { create :project }

    it 'does not allow more than one active issue tracker service' do
      create(:service, project: project, active: true, category: 'issue_tracker')
      redmine_service = RedmineService.new(project: project, active: true)

      expect(redmine_service).not_to be_valid
      expect(redmine_service.errors[:base]).to include(
        'Another issue tracker is already in use. Only one issue tracker service can be active at a time'
      )
    end
  end
end
