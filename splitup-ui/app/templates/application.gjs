import Component from '@glimmer/component';
import { service } from '@ember/service';
import { pageTitle } from 'ember-page-title';
import RouteTemplate from 'ember-route-template';
import Sidebar from 'splitup-ui/components/sidebar';
import ToastContainer from 'splitup-ui/components/toast-container';

class ApplicationTemplate extends Component {
  @service auth;

  <template>
    {{pageTitle "SplitUp"}}
    <ToastContainer />
    {{#if this.auth.isAuthenticated}}
      <div class="app-body">
        <Sidebar />
        <main class="main-content">
          {{outlet}}
        </main>
      </div>
    {{else}}
      {{outlet}}
    {{/if}}
  </template>
}

export default RouteTemplate(ApplicationTemplate);
