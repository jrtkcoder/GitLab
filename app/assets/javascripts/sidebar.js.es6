/* eslint-disable arrow-parens, class-methods-use-this, no-param-reassign */
/* global Cookies */

(() => {
  const pinnedStateCookie = 'pin_nav';
  const sidebarBreakpoint = 1024;

  const pageSelector = '.page-with-sidebar';
  const navbarSelector = '.navbar-gitlab';
  const sidebarWrapperSelector = '.sidebar-wrapper';
  const sidebarContentSelector = '.nav-sidebar';

  const pinnedToggleSelector = '.js-nav-pin';
  const sidebarToggleSelector = '.toggle-nav-collapse, .side-nav-toggle';

  const pinnedPageClass = 'page-sidebar-pinned';
  const expandedPageClass = 'page-sidebar-expanded';

  const pinnedNavbarClass = 'header-sidebar-pinned';
  const expandedNavbarClass = 'header-sidebar-expanded';

  class Sidebar {
    constructor() {
      if (!Sidebar.singleton) {
        Sidebar.singleton = this;
        Sidebar.singleton.init();
      }

      return Sidebar.singleton;
    }

    init() {
      this.isPinned = Cookies.get(pinnedStateCookie) === 'true';
      this.isExpanded = (
        window.innerWidth >= sidebarBreakpoint &&
        $(pageSelector).hasClass(expandedPageClass)
      );
      $(window).on('resize', () => this.setSidebarHeight());
      $(document)
        .on('click', sidebarToggleSelector, () => this.toggleSidebar())
        .on('click', pinnedToggleSelector, () => this.togglePinnedState())
        .on('click', 'html, body, a, button', (e) => this.handleClickEvent(e))
        .on('DOMContentLoaded', () => this.renderState())
        .on('scroll', () => this.setSidebarHeight())
        .on('todo:toggle', (e, count) => this.updateTodoCount(count));
      this.renderState();
      this.setSidebarHeight();
    }

    handleClickEvent(e) {
      if (this.isExpanded && (!this.isPinned || window.innerWidth < sidebarBreakpoint)) {
        const $target = $(e.target);
        const targetIsToggle = $target.closest(sidebarToggleSelector).length > 0;
        const targetIsSidebar = $target.closest(sidebarWrapperSelector).length > 0;
        if (!targetIsToggle && (!targetIsSidebar || $target.closest('a'))) {
          this.toggleSidebar();
        }
      }
    }

    updateTodoCount(count) {
      $('.js-todos-count').text(gl.text.addDelimiter(count));
    }

    toggleSidebar() {
      this.isExpanded = !this.isExpanded;
      this.renderState();
    }

    setSidebarHeight() {
      const $navHeight = $('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight();
      const diff = $navHeight - $('body').scrollTop();
      if (diff > 0) {
        $('.js-right-sidebar').outerHeight($(window).height() - diff);
      } else {
        $('.js-right-sidebar').outerHeight('100%');
      }
    }

    togglePinnedState() {
      this.isPinned = !this.isPinned;
      if (!this.isPinned) {
        this.isExpanded = false;
      }
      Cookies.set(pinnedStateCookie, this.isPinned ? 'true' : 'false', { expires: 3650 });
      this.renderState();
    }

    renderState() {
      $(pageSelector)
        .toggleClass(pinnedPageClass, this.isPinned && this.isExpanded)
        .toggleClass(expandedPageClass, this.isExpanded);
      $(navbarSelector)
        .toggleClass(pinnedNavbarClass, this.isPinned && this.isExpanded)
        .toggleClass(expandedNavbarClass, this.isExpanded);

      const $pinnedToggle = $(pinnedToggleSelector);
      const tooltipText = this.isPinned ? 'Unpin navigation' : 'Pin navigation';
      const tooltipState = $pinnedToggle.attr('aria-describedby') && this.isExpanded ? 'show' : 'hide';
      $pinnedToggle.attr('title', tooltipText).tooltip('fixTitle').tooltip(tooltipState);

      if (this.isExpanded) {
        const sidebarContent = $(sidebarContentSelector);
        setTimeout(() => { sidebarContent.niceScroll().updateScrollBar(); }, 200);
      }
    }
  }

  window.gl = window.gl || {};
  gl.Sidebar = Sidebar;
})();
