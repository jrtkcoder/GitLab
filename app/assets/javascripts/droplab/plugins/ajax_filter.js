!function(t){function e(r){if(i[r])return i[r].exports;var o=i[r]={i:r,l:!1,exports:{}};return t[r].call(o.exports,o,o.exports,e),o.l=!0,o.exports}var i={};return e.m=t,e.c=i,e.i=function(t){return t},e.d=function(t,i,r){e.o(t,i)||Object.defineProperty(t,i,{configurable:!1,enumerable:!0,get:r})},e.n=function(t){var i=t&&t.__esModule?function(){return t.default}:function(){return t};return e.d(i,"a",i),i},e.o=function(t,e){return Object.prototype.hasOwnProperty.call(t,e)},e.p="",e(e.s=11)}({11:function(t,e,i){"use strict";Object.defineProperty(e,"__esModule",{value:!0});var r={init:function(t){this.destroyed=!1,this.hook=t,this.notLoading(),this.eventWrapper={},this.eventWrapper.debounceTrigger=this.debounceTrigger.bind(this),this.hook.trigger.addEventListener("keydown.dl",this.eventWrapper.debounceTrigger),this.hook.trigger.addEventListener("focus",this.eventWrapper.debounceTrigger),this.trigger(!0)},notLoading:function(){this.loading=!1},debounceTrigger:function(t){var e=[16,17,18,20,37,38,39,40,91,93],i=e.indexOf(t.detail.which||t.detail.keyCode)>-1,r="focus"===t.type;i||this.loading||(this.timeout&&clearTimeout(this.timeout),this.timeout=setTimeout(this.trigger.bind(this,r),200))},trigger:function(t){var e=this.hook.config.droplabAjaxFilter,i=this.trigger.value;if(e&&e.endpoint&&e.searchKey){if(e.searchValueFunction&&(i=e.searchValueFunction()),e.loadingTemplate&&void 0===this.hook.list.data||0===this.hook.list.data.length){var r=this.hook.list.list.querySelector("[data-dynamic]"),o=document.createElement("div");o.innerHTML=e.loadingTemplate,o.setAttribute("data-loading-template",!0),this.listTemplate=r.outerHTML,r.outerHTML=o.outerHTML}if(t&&(i=""),e.searchKey===i)return this.list.show();this.loading=!0;var n=e.params||{};n[e.searchKey]=i;var a=this;a.cache=a.cache||{};var s=e.endpoint+this.buildParams(n),u=a.cache[s];u?a._loadData(u,e,a):this._loadUrlData(s).then(function(t){a._loadData(t,e,a)})}},_loadUrlData:function(t){var e=this;return new Promise(function(i,r){var o=new XMLHttpRequest;o.open("GET",t,!0),o.onreadystatechange=function(){if(o.readyState===XMLHttpRequest.DONE){if(200===o.status){var n=JSON.parse(o.responseText);return e.cache[t]=n,i(n)}return r([o.responseText,o.status])}},o.send()})},_loadData:function(t,e,i){if(e.loadingTemplate&&void 0===i.hook.list.data||0===i.hook.list.data.length){var r=i.hook.list.list.querySelector("[data-loading-template]");r&&(r.outerHTML=i.listTemplate)}if(!i.destroyed){var o=i.hook.list.list.children,n=1===o.length&&o[0].hasAttribute("data-dynamic");n&&0===t.length&&i.hook.list.hide(),i.hook.list.setData.call(i.hook.list,t)}i.notLoading(),i.hook.list.currentIndex=0},buildParams:function(t){if(!t)return"";var e=Object.keys(t).map(function(e){return e+"="+(t[e]||"")});return"?"+e.join("&")},destroy:function(){this.timeout&&clearTimeout(this.timeout),this.destroyed=!0,this.hook.trigger.removeEventListener("keydown.dl",this.eventWrapper.debounceTrigger),this.hook.trigger.removeEventListener("focus",this.eventWrapper.debounceTrigger)}};window.droplabAjaxFilter=r,e.default=r}});
//# sourceMappingURL=ajax_filter.js.map