import Vue from 'vue';

export default class EnvironmentsService {
  constructor(endpoint) {
    this.environments = Vue.resource(endpoint);
  }

  all() {
    return this.environments.get();
  }
}
