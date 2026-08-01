import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';

export default class TopHeader extends Component {
  @service auth;
  @service router;

  @tracked menuOpen = false;

  @action toggleMenu() {
    this.menuOpen = !this.menuOpen;
  }

  @action logout() {
    this.auth.logout();
    this.router.transitionTo('login');
  }

  <template>
    <header class="top-header">
      <LinkTo @route="index" class="brand">
        <span class="brand-icon">S</span>
        <span class="brand-name">SplitUp</span>
      </LinkTo>

      <div class="header-user" {{on "click" this.toggleMenu}}>
        <span class="header-avatar">{{this.auth.userEmail.[0]}}</span>
        <span class="header-email">{{this.auth.userEmail}}</span>
        <span class="header-caret">▾</span>

        {{#if this.menuOpen}}
          <div class="header-menu">
            <button type="button" class="header-menu-item" {{on "click" this.logout}}>
              Logout
            </button>
          </div>
        {{/if}}
      </div>
    </header>
  </template>
}
