import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, click, settled } from '@ember/test-helpers';
import Service from '@ember/service';
import Sidebar from 'splitup-ui/components/sidebar';

class MockAuthService extends Service {
  userId = '1';
  userEmail = 'me@example.com';
  isAuthenticated = true;
}

class MockApiService extends Service {
  friends = [
    { id: 2, firstName: 'Jane', lastName: 'Doe', emailId: 'jane@example.com', balanceDto: { amount: 30, currency_code: 'USD' } },
    { id: 3, firstName: 'Alex', lastName: 'Kim', emailId: 'alex@example.com', balanceDto: { amount: 0, currency_code: 'USD' } },
  ];
  groups = [{ id: 5, name: 'Summer Trip', members: [] }];

  get(path) {
    if (path.includes('/friends/')) return Promise.resolve({ code: 0, data: this.friends });
    return Promise.resolve({ code: 0, data: this.groups });
  }
}

class MockRouterService extends Service {
  transitions = [];
  on() {}
  off() {}
  transitionTo(routeName) {
    this.transitions.push(routeName);
  }
}

class MockToastService extends Service {
  success() {}
  error() {}
  info() {}
}

module('Integration | Component | sidebar', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:api', MockApiService);
    this.owner.register('service:router', MockRouterService);
    this.owner.register('service:toast', MockToastService);
  });

  test('renders the brand name', async function (assert) {
    await render(<template><Sidebar /></template>);
    await settled();

    assert.dom('.sidebar-brand-name').hasText('SplitUp');
  });

  test('renders 5 main nav links', async function (assert) {
    await render(<template><Sidebar /></template>);
    await settled();

    assert.dom('.sidebar-nav-link').exists({ count: 5 });
  });

  test('loads and renders group items in the sidebar', async function (assert) {
    await render(<template><Sidebar /></template>);
    await settled();

    assert.dom('.sidebar-group-item').exists({ count: 1 });
    assert.dom('.sidebar-group-item .sidebar-item-name').hasText('Summer Trip');
  });

  test('loads and renders friend items in the sidebar', async function (assert) {
    await render(<template><Sidebar /></template>);
    await settled();

    assert.dom('.sidebar-friend-item').exists({ count: 2 });
  });

  test('shows a balance badge for friends with non-zero balance', async function (assert) {
    await render(<template><Sidebar /></template>);
    await settled();

    // Jane has USD 30 balance — should have a badge
    assert.dom('.sidebar-friend-item .sidebar-item-badge').exists({ count: 1 });
    assert.dom('.sidebar-friend-item .sidebar-item-badge').includesText('USD 30.00');
  });

  test('renders the user footer with initials and logout button', async function (assert) {
    await render(<template><Sidebar /></template>);
    await settled();

    assert.dom('.sidebar-user-avatar').exists();
    assert.dom('.sidebar-user-email').hasText('me@example.com');
    assert.dom('.sidebar-logout-btn').exists();
  });

  test('clicking the logout button calls auth.logout and navigates to login', async function (assert) {
    let logoutCalled = false;
    class MockAuthWithLogout extends MockAuthService {
      logout() { logoutCalled = true; }
    }
    this.owner.register('service:auth', MockAuthWithLogout);

    await render(<template><Sidebar /></template>);
    await settled();

    await click('.sidebar-logout-btn');

    assert.ok(logoutCalled, 'auth.logout() was called');
    const router = this.owner.lookup('service:router');
    assert.strictEqual(router.transitions[0], 'login');
  });
});
