const GROUP_LIMIT = 2;

export default class ProjectName {
  constructor() {
    this.title = document.querySelector('.title');
    this.groups = document.querySelectorAll('.group-path');
    this.groupTitle = document.querySelector('.group-title');
    this.toggle = null;
    this.isHidden = false;
    this.init();
  }

  init() {
    if (this.groups.length > GROUP_LIMIT) {
      this.groups[this.groups.length - 1].classList.remove('hidable');
      this.addToggle();
    }
    this.render();
  }

  addToggle() {
    const header = document.querySelector('.header-content');
    this.toggle = document.createElement('button');
    this.toggle.className = 'text-expander project-name-toggle';
    this.toggle.setAttribute('aria-label', 'Show all');
    this.toggle.innerHTML = '...';
    this.toggleGroups();
    header.insertBefore(this.toggle, this.title);
    this.toggle.addEventListener('click', this.toggleGroups.bind(this));
  }

  toggleGroups() {
    this.groupTitle.classList.toggle('is-hidden');
    this.isHidden = !this.isHidden;
  }

  render() {
    this.title.classList.remove('initializing');
  }
}
