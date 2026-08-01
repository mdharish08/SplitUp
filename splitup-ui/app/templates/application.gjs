import Component from '@glimmer/component';
import { service } from '@ember/service';
import { pageTitle } from 'ember-page-title';
import RouteTemplate from 'ember-route-template';
import TopHeader from 'splitup-ui/components/top-header';
import Sidebar from 'splitup-ui/components/sidebar';

class ApplicationTemplate extends Component {
  @service auth;

  <template>
    {{pageTitle "SplitUp"}}
    {{#if this.auth.isAuthenticated}}
      <TopHeader />
      <div class="app-body">
        <Sidebar />
        <main class="main-content">
          {{outlet}}
        </main>
      </div>
    {{else}}
      <main class="main-content">
        {{outlet}}
      </main>
    {{/if}}
  </template>
}

export default RouteTemplate(ApplicationTemplate);
