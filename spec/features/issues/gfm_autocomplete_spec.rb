require 'rails_helper'

feature 'GFM autocomplete', feature: true, js: true do
  include WaitForAjax
  let(:user)    { create(:user, username: 'someone.special') }
  let(:project) { create(:project) }
  let(:label) { create(:label, project: project, title: 'special+') }
  let(:issue)   { create(:issue, project: project) }

  before do
    project.team << [user, :master]
    login_as(user)
    visit namespace_project_issue_path(project.namespace, project, issue)

    wait_for_ajax
  end

  it 'opens autocomplete menu when field starts with text' do
    page.within '.timeline-content-form' do
      find('#note_note').native.send_keys('')
      find('#note_note').native.send_keys('@')
    end

    expect(page).to have_selector('.atwho-container')
  end

  it 'doesnt open autocomplete menu character is prefixed with text' do
    page.within '.timeline-content-form' do
      find('#note_note').native.send_keys('testing')
      find('#note_note').native.send_keys('@')
    end

    expect(page).not_to have_selector('.atwho-view')
  end

  context 'if a selected value has special characters' do
    it 'wraps the result in double quotes' do
      note = find('#note_note')
      page.within '.timeline-content-form' do
        note.native.send_keys('')
        note.native.send_keys("~#{label.title[0]}")
        sleep 1
        note.click
      end

      label_item = find('.atwho-view li', text: label.title)

      expect_to_wrap(true, label_item, note, label.title)
    end

    it 'doesn\'t wrap for assignee values' do
      note = find('#note_note')
      page.within '.timeline-content-form' do
        note.native.send_keys('')
        note.native.send_keys("@#{user.username[0]}")
        sleep 1
        note.click
      end

      user_item = find('.atwho-view li', text: user.username)

      expect_to_wrap(false, user_item, note, user.username)
    end

    it 'doesn\'t wrap for emoji values' do
      note = find('#note_note')
      page.within '.timeline-content-form' do
        note.native.send_keys('')
        note.native.send_keys(":cartwheel")
        sleep 1
        note.click
      end

      emoji_item = find('.atwho-view li', text: 'cartwheel_tone1')

      expect_to_wrap(false, emoji_item, note, 'cartwheel_tone1')
    end

    def expect_to_wrap(should_wrap, item, note, value)
      expect(item).to have_content(value)
      expect(item).not_to have_content("\"#{value}\"")

      item.click

      if should_wrap
        expect(note.value).to include("\"#{value}\"")
      else
        expect(note.value).not_to include("\"#{value}\"")
      end
    end
  end
end
