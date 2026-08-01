import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, click } from '@ember/test-helpers';
import Service from '@ember/service';
import TopHeader from 'splitup-ui/components/top-header';

class MockAuthService extends Service {
  userEmail = 'me@example.com';
  loggedOut = false;
  logout() {
    this.loggedOut = true;
  }
}

class MockRouterService extends Service {
  transitions = [];
  transitionTo(routeName) {
    this.transitions.push(routeName);
  }
}

module('Integration | Component | top-header', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:router', MockRouterService);
  });

  test('shows the user email and hides the menu by default', async function (assert) {
    await render(<template><TopHeader /></template>);

    assert.dom('.header-email').hasText('me@example.com');
    assert.dom('.header-menu').doesNotExist();
  });

  test('clicking the user area toggles the logout menu open and closed', async function (assert) {
    await render(<template><TopHeader /></template>);

    await click('.header-user');
    assert.dom('.header-menu').exists();

    await click('.header-user');
    assert.dom('.header-menu').doesNotExist();
  });

  test('clicking logout calls auth.logout and redirects to login', async function (assert) {
    await render(<template><TopHeader /></template>);

    await click('.header-user');
    await click('.header-menu-item');

    const auth = this.owner.lookup('service:auth');
    const router = this.owner.lookup('service:router');

    assert.true(auth.loggedOut);
    assert.strictEqual(router.transitions[0], 'login');
  });
});
