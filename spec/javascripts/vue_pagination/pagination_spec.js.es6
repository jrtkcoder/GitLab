//= require vue
//= require lib/utils/common_utils
//= require vue_pagination/index
/* global fixture, gl */

describe('Pagination component', () => {
  let component;

  const changeChanges = {
    one: '',
    two: '',
  };

  const change = (one, two) => {
    changeChanges.one = one;
    changeChanges.two = two;
  };

  it('should render and start at page 1', () => {
    fixture.set('<div class="test-pagination-container"></div>');

    component = new window.gl.VueGlPagination({
      el: document.querySelector('.test-pagination-container'),
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 2,
          previousPage: '',
        },
        change,
      },
    });

    expect(component.$el.classList).toContain('gl-pagination');

    component.changePage({ target: { innerText: '1' } });

    expect(changeChanges.one).toEqual(1);
    expect(changeChanges.two).toEqual('all');
  });

  it('should go to the previous page', () => {
    fixture.set('<div class="test-pagination-container"></div>');

    component = new window.gl.VueGlPagination({
      el: document.querySelector('.test-pagination-container'),
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 3,
          previousPage: 1,
        },
        change,
      },
    });

    component.changePage({ target: { innerText: 'Prev' } });

    expect(changeChanges.one).toEqual(1);
    expect(changeChanges.two).toEqual('all');
  });

  it('should go to the next page', () => {
    fixture.set('<div class="test-pagination-container"></div>');

    component = new window.gl.VueGlPagination({
      el: document.querySelector('.test-pagination-container'),
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 5,
          previousPage: 3,
        },
        change,
      },
    });

    component.changePage({ target: { innerText: 'Next' } });

    expect(changeChanges.one).toEqual(5);
    expect(changeChanges.two).toEqual('all');
  });

  it('should go to the last page', () => {
    fixture.set('<div class="test-pagination-container"></div>');

    component = new window.gl.VueGlPagination({
      el: document.querySelector('.test-pagination-container'),
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 5,
          previousPage: 3,
        },
        change,
      },
    });

    component.changePage({ target: { innerText: 'Last >>' } });

    expect(changeChanges.one).toEqual(10);
    expect(changeChanges.two).toEqual('all');
  });

  it('should go to the first page', () => {
    fixture.set('<div class="test-pagination-container"></div>');

    component = new window.gl.VueGlPagination({
      el: document.querySelector('.test-pagination-container'),
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 5,
          previousPage: 3,
        },
        change,
      },
    });

    component.changePage({ target: { innerText: '<< First' } });

    expect(changeChanges.one).toEqual(1);
    expect(changeChanges.two).toEqual('all');
  });

  it('should do nothing', () => {
    fixture.set('<div class="test-pagination-container"></div>');

    component = new window.gl.VueGlPagination({
      el: document.querySelector('.test-pagination-container'),
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 2,
          previousPage: '',
        },
        change,
      },
    });

    component.changePage({ target: { innerText: '...' } });

    expect(changeChanges.one).toEqual(1);
    expect(changeChanges.two).toEqual('all');
  });
});

describe('paramHelper', () => {
  it('can parse url parameters correctly', () => {
    window.history.pushState({}, null, '?scope=all&p=2');

    const scope = gl.utils.getParameterByName('scope');
    const p = gl.utils.getParameterByName('p');

    expect(scope).toEqual('all');
    expect(p).toEqual('2');
  });

  it('returns null if param not in url', () => {
    window.history.pushState({}, null, '?p=2');

    const scope = gl.utils.getParameterByName('scope');
    const p = gl.utils.getParameterByName('p');

    expect(scope).toEqual(null);
    expect(p).toEqual('2');
  });
});
