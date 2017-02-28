/* global UsersSelect, GitLabDropdownRemote */

import '~/users_select';
import '~/gl_dropdown';

describe('UsersSelect', () => {
  preloadFixtures('issues/edit.html.raw');

  describe('init', () => {
    beforeEach(() => {
      loadFixtures('issues/edit.html.raw');
    });

    afterEach(() => {
      this.usersSelect = null;
    });

    it('updates assignee on click', () => {
      window.gon = {
        current_user_id: 1,
      };

      const inputField = $('#issue_assignee_id');
      this.usersSelect = new UsersSelect();
      expect(inputField.val()).toBe('');

      $('.assign-to-me-link').click();
      expect(inputField.val()).toBe('1');
    });

    it('updates user name on click', () => {
      window.gon = {
        current_user_fullname: 'Real Person',
      };

      const nameField = $('.js-user-search .dropdown-toggle-text');

      this.usersSelect = new UsersSelect();
      expect(nameField.text()).toBe('Assignee');

      $('.assign-to-me-link').click();
      expect(nameField.text()).toBe('Real Person');
    });
  });
});
