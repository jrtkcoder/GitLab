/* eslint-disable func-names, space-before-function-paren, no-template-curly-in-string, comma-dangle, object-shorthand, quotes, dot-notation, no-else-return, one-var, no-var, no-underscore-dangle, one-var-declaration-per-line, no-param-reassign, no-useless-escape, prefer-template, consistent-return, wrap-iife, prefer-arrow-callback, camelcase, no-unused-vars, no-useless-return, padded-blocks, vars-on-top, indent, no-extra-semi, no-multi-spaces, semi, max-len */

// Creates the variables for setting up GFM auto-completion
(function() {
  if (window.GitLab == null) {
    window.GitLab = {};
  }

  function sanitize(str) {
    return str.replace(/<(?:.|\n)*?>/gm, '');
  }

  window.GitLab.GfmAutoComplete = {
    dataLoading: false,
    dataLoaded: false,
    cachedData: {},
    dataSource: '',
    // Emoji
    Emoji: {
      template: '<li>${name} <img alt="${name}" height="20" src="${path}" width="20" /></li>'
    },
    // Team Members
    Members: {
      template: '<li>${avatarTag} ${username} <small>${title}</small></li>'
    },
    Labels: {
      template: '<li><span class="dropdown-label-box" style="background: ${color}"></span> ${title}</li>'
    },
    // Issues and MergeRequests
    Issues: {
      template: '<li><small>${id}</small> ${title}</li>'
    },
    // Milestones
    Milestones: {
      template: '<li>${title}</li>'
    },
    Loading: {
      template: '<li><i class="fa fa-refresh fa-spin"></i> Loading...</li>'
    },
    DefaultOptions: {
      sorter: function(query, items, searchKey) {
        // Highlight first item only if at least one char was typed
        this.setting.highlightFirst = this.setting.alwaysHighlightFirst || query.length > 0;
        if ((items[0].name != null) && items[0].name === 'loading') {
          return items;
        }
        return $.fn.atwho["default"].callbacks.sorter(query, items, searchKey);
      },
      filter: function(query, data, searchKey) {
        if (data[0] === 'loading') {
          return data;
        }
        return $.fn.atwho["default"].callbacks.filter(query, data, searchKey);
      },
      beforeInsert: function(value) {
        if (value && !this.setting.skipSpecialCharacterTest) {
          var withoutAt = value.substring(1);
          if (withoutAt && /[^\w\d]/.test(withoutAt)) value = value.charAt() + '"' + withoutAt + '"';
        }
        if (!window.GitLab.GfmAutoComplete.dataLoaded) {
          return this.at;
        } else {
          return value;
        }
      },
      matcher: function (flag, subtext) {
        // The below is taken from At.js source
        // Tweaked to commands to start without a space only if char before is a non-word character
        // https://github.com/ichord/At.js
        var _a, _y, regexp, match;
        subtext = subtext.split(' ').pop();
        flag = flag.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");

        _a = decodeURI("%C3%80");
        _y = decodeURI("%C3%BF");

        regexp = new RegExp("(?:\\B|\\W|\\s)" + flag + "(?!\\W)([A-Za-z" + _a + "-" + _y + "0-9_\'\.\+\-]*)|([^\\x00-\\xff]*)$", 'gi');

        match = regexp.exec(subtext);

        if (match) {
          return match[2] || match[1];
        } else {
          return null;
        }
      }
    },
    setup: _.debounce(function(input) {
      // Add GFM auto-completion to all input fields, that accept GFM input.
      this.input = input || $('.js-gfm-input');
      // destroy previous instances
      this.destroyAtWho();
      // set up instances
      this.setupAtWho();

      if (this.dataSource && !this.dataLoading && !this.cachedData) {
        this.dataLoading = true;
        return this.fetchData(this.dataSource)
          .done((data) => {
            this.dataLoading = false;
            this.loadData(data);
          });
        };

      if (this.cachedData != null) {
        return this.loadData(this.cachedData);
      }
    }, 1000),
    setupAtWho: function() {
      // Emoji
      this.input.atwho({
        at: ':',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.path != null) {
              return _this.Emoji.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        insertTpl: ':${name}:',
        data: ['loading'],
        startWithSpace: false,
        skipSpecialCharacterTest: true,
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          matcher: this.DefaultOptions.matcher
        }
      });
      // Team Members
      this.input.atwho({
        at: '@',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.username != null) {
              return _this.Members.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        insertTpl: '${atwho-at}${username}',
        searchKey: 'search',
        data: ['loading'],
        startWithSpace: false,
        alwaysHighlightFirst: true,
        skipSpecialCharacterTest: true,
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          matcher: this.DefaultOptions.matcher,
          beforeSave: function(members) {
            return $.map(members, function(m) {
              let title = '';
              if (m.username == null) {
                return m;
              }
              title = m.name;
              if (m.count) {
                title += " (" + m.count + ")";
              }

              const autoCompleteAvatar = m.avatar_url || m.username.charAt(0).toUpperCase();
              const imgAvatar = `<img src="${m.avatar_url}" alt="${m.username}" class="avatar avatar-inline center s26"/>`;
              const txtAvatar = `<div class="avatar center avatar-inline s26">${autoCompleteAvatar}</div>`;

              return {
                username: m.username,
                avatarTag: autoCompleteAvatar.length === 1 ?  txtAvatar : imgAvatar,
                title: sanitize(title),
                search: sanitize(m.username + " " + m.name)
              };
            });
          }
        }
      });
      this.input.atwho({
        at: '#',
        alias: 'issues',
        searchKey: 'search',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.title != null) {
              return _this.Issues.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        data: ['loading'],
        insertTpl: '${atwho-at}${id}',
        startWithSpace: false,
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          matcher: this.DefaultOptions.matcher,
          beforeSave: function(issues) {
            return $.map(issues, function(i) {
              if (i.title == null) {
                return i;
              }
              return {
                id: i.iid,
                title: sanitize(i.title),
                search: i.iid + " " + i.title
              };
            });
          }
        }
      });
      this.input.atwho({
        at: '%',
        alias: 'milestones',
        searchKey: 'search',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.title != null) {
              return _this.Milestones.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        insertTpl: '${atwho-at}${title}',
        data: ['loading'],
        startWithSpace: false,
        callbacks: {
          matcher: this.DefaultOptions.matcher,
          sorter: this.DefaultOptions.sorter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          beforeSave: function(milestones) {
            return $.map(milestones, function(m) {
              if (m.title == null) {
                return m;
              }
              return {
                id: m.iid,
                title: sanitize(m.title),
                search: "" + m.title
              };
            });
          }
        }
      });
      this.input.atwho({
        at: '!',
        alias: 'mergerequests',
        searchKey: 'search',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.title != null) {
              return _this.Issues.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        data: ['loading'],
        startWithSpace: false,
        insertTpl: '${atwho-at}${id}',
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          matcher: this.DefaultOptions.matcher,
          beforeSave: function(merges) {
            return $.map(merges, function(m) {
              if (m.title == null) {
                return m;
              }
              return {
                id: m.iid,
                title: sanitize(m.title),
                search: m.iid + " " + m.title
              };
            });
          }
        }
      });
      this.input.atwho({
        at: '~',
        alias: 'labels',
        searchKey: 'search',
        displayTpl: this.Labels.template,
        insertTpl: '${atwho-at}${title}',
        startWithSpace: false,
        callbacks: {
          matcher: this.DefaultOptions.matcher,
          sorter: this.DefaultOptions.sorter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          beforeSave: function(merges) {
            return $.map(merges, function(m) {
              return {
                title: sanitize(m.title),
                color: m.color,
                search: "" + m.title
              };
            });
          }
        }
      });
      // We don't instantiate the slash commands autocomplete for note and issue/MR edit forms
      this.input.filter('[data-supports-slash-commands="true"]').atwho({
        at: '/',
        alias: 'commands',
        searchKey: 'search',
        skipSpecialCharacterTest: true,
        displayTpl: function(value) {
          var tpl = '<li>/${name}';
          if (value.aliases.length > 0) {
            tpl += ' <small>(or /<%- aliases.join(", /") %>)</small>';
          }
          if (value.params.length > 0) {
            tpl += ' <small><%- params.join(" ") %></small>';
          }
          if (value.description !== '') {
            tpl += '<small class="description"><i><%- description %></i></small>';
          }
          tpl += '</li>';
          return _.template(tpl)(value);
        },
        insertTpl: function(value) {
          var tpl = "/${name} ";
          var reference_prefix = null;
          if (value.params.length > 0) {
            reference_prefix = value.params[0][0];
            if (/^[@%~]/.test(reference_prefix)) {
              tpl += '<%- reference_prefix %>';
            }
          }
          return _.template(tpl)({ reference_prefix: reference_prefix });
        },
        suffix: '',
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          beforeSave: function(commands) {
            return $.map(commands, function(c) {
              var search = c.name;
              if (c.aliases.length > 0) {
                search = search + " " + c.aliases.join(" ");
              }
              return {
                name: c.name,
                aliases: c.aliases,
                params: c.params,
                description: c.description,
                search: search
              };
            });
          },
          matcher: function(flag, subtext, should_startWithSpace, acceptSpaceBar) {
            var regexp = /(?:^|\n)\/([A-Za-z_]*)$/gi
            var match = regexp.exec(subtext);
            if (match) {
              return match[1];
            } else {
              return null;
            }
          }
        }
      });
      return;
    },
    destroyAtWho: function() {
      return this.input.atwho('destroy');
    },
    fetchData: function(dataSource) {
      return $.getJSON(dataSource);
    },
    loadData: function(data) {
      this.cachedData = data;
      this.dataLoaded = true;
      // load members
      this.input.atwho('load', '@', data.members);
      // load issues
      this.input.atwho('load', 'issues', data.issues);
      // load milestones
      this.input.atwho('load', 'milestones', data.milestones);
      // load merge requests
      this.input.atwho('load', 'mergerequests', data.mergerequests);
      // load emojis
      this.input.atwho('load', ':', data.emojis);
      // load labels
      this.input.atwho('load', '~', data.labels);
      // load commands
      this.input.atwho('load', '/', data.commands);
      // This trigger at.js again
      // otherwise we would be stuck with loading until the user types
      return $(':focus').trigger('keyup');
    }
  };

}).call(this);
