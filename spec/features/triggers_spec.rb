require 'spec_helper'

feature 'Triggers', feature: true, js: true do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  before { login_as(user) }

  before do
    @project = FactoryGirl.create :empty_project
    @project.team << [user, :master]
    @project.team << [user2, :master]
    visit namespace_project_settings_ci_cd_path(@project.namespace, @project)
  end

  describe 'create trigger workflow' do
    scenario 'prevents adding new trigger with no description' do
      fill_in 'trigger_description', with: ''
      click_button 'Add trigger'
      expect(page.find('form.gl-show-field-errors .gl-field-error')['style']).to eq 'display: block;'
    end

    scenario 'adds new trigger with description' do
      fill_in 'trigger_description', with: 'trigger desc'
      click_button 'Add trigger'
      expect(page.find('.flash-notice')).to have_content 'Trigger was created successfully.'
      expect(page.find('.triggers-list')).to have_content 'trigger desc'
      expect(page.find('.triggers-list .trigger-owner')).to have_content @user.name
    end
  end

  describe 'edit trigger workflow' do
    before(:each) do
      fill_in 'trigger_description', with: 'trigger desc'
      click_button 'Add trigger'
    end

    scenario 'click on edit trigger opens edit trigger page' do
      find('a[title="Edit"]').click
      expect(page.find('#trigger_description').value).to have_content 'trigger desc'
    end

    scenario 'edit trigger description and save' do
      trigger_title = 'new trigger'
      find('a[title="Edit"]').click
      fill_in 'trigger_description', with: trigger_title
      click_button 'Save trigger'
      expect(page.find('.flash-notice')).to have_content 'Trigger was successfully updated.'
      expect(page.find('.triggers-list')).to have_content trigger_title
      expect(page.find('.triggers-list .trigger-owner')).to have_content @user.name
    end
  end

  describe 'trigger "Take ownership" workflow' do
    trigger_title = 'trigger desc'

    before(:each) do
      fill_in 'trigger_description', with: trigger_title
      click_button 'Add trigger'
    end

    scenario 'button "Take ownership" has correct alert' do
      logout
      login_with(user2)
      visit namespace_project_settings_ci_cd_path(@project.namespace, @project)
      expected_alert = 'By taking ownership you will bind this trigger to your user account. With this the trigger will have access to all your projects as if it was you. Are you sure?'
      expect(page.find('a.btn-trigger-take-ownership')['data-confirm']).to eq expected_alert
    end

    scenario 'take trigger ownership' do
      logout
      login_with(user2)
      visit namespace_project_settings_ci_cd_path(@project.namespace, @project)
      find('a.btn-trigger-take-ownership').click
      page.accept_confirm do
        expect(page.find('.flash-notice')).to have_content 'Trigger was created successfully.'
        expect(page.find('.triggers-list')).to have_content trigger_title
      end
    end
  end

  describe 'trigger "Revoke" workflow' do
    trigger_title = 'trigger desc'

    before(:each) do
      fill_in 'trigger_description', with: trigger_title
      click_button 'Add trigger'
    end

    scenario 'button "Revoke" has correct alert' do
      expected_alert = 'By revoking a trigger you will corrupt any processes making use of it. Are you sure?'
      expect(page.find('a.btn-trigger-revoke')['data-confirm']).to eq expected_alert
    end

    scenario 'revoke trigger' do
      find('a.btn-trigger-revoke').click
      page.accept_confirm do
        expect(page.find('.flash-notice')).to have_content 'Trigger removed'
      end
    end
  end

  describe 'show triggers workflow' do
    trigger_title = 'trigger desc'

    scenario 'contains trigger description placeholder' do
      expect(page.find('#trigger_description')['placeholder']).to eq 'Trigger description'
    end

    scenario 'show "Edit" only for non-legacy trigger' do
      fill_in 'trigger_description', with: trigger_title
      click_button 'Add trigger'
      expect(page.find('.triggers-list')).not_to have_content 'legacy'
      expect(page.find('.triggers-list')).to have_selector('a[title="Edit"]')
    end

    scenario 'show full token for owned trigger' do
      fill_in 'trigger_description', with: trigger_title
      click_button 'Add trigger'
      expect(page.find('.triggers-list')).to have_content @project.triggers.first.token
      expect(page.find('.triggers-list')).to have_selector('button.btn-clipboard')
    end

    scenario 'show only first 8 characters of token for trigger not owned' do
      fill_in 'trigger_description', with: trigger_title
      click_button 'Add trigger'
      logout
      login_with(user2)
      visit namespace_project_settings_ci_cd_path(@project.namespace, @project)
      expect(page.find('.triggers-list')).to have_content(@project.triggers.first.token[0..7] + '...')
      expect(page.find('.triggers-list')).not_to have_selector('button.btn-clipboard')
    end
  end
end
