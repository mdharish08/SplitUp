import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, fillIn, click, settled } from '@ember/test-helpers';
import Service from '@ember/service';
import Sidebar from 'splitup-ui/components/sidebar';

class MockAuthService extends Service {
  userId = '1';
  isAuthenticated = true;
}

class MockApiService extends Service {
  friends = [
    { id: 2, firstName: 'Jane', lastName: 'Doe', emailId: 'jane@example.com' },
    { id: 3, firstName: 'Alex', lastName: 'Kim', emailId: 'alex@example.com' },
  ];
  groups = [{ id: 5, name: 'Summer Trip' }];
  posts = [];

  get(path) {
    if (path.includes('/friends/')) return Promise.resolve({ code: 0, data: this.friends });
    return Promise.resolve({ code: 0, data: this.groups });
  }

  post(path, body) {
    this.posts.push({ path, body });
    return Promise.resolve({ code: 0, data: { id: 9 } });
  }
}

class MockRouterService extends Service {
  on() {}
  off() {}
}

module('Integration | Component | sidebar', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:api', MockApiService);
    this.owner.register('service:router', MockRouterService);
  });

  test('loads and renders friends and groups on construction', async function (assert) {
    await render(<template><Sidebar /></template>);
    await settled();

    assert.dom('.sidebar-list').exists({ count: 2 });
    assert.dom('.sidebar-section:nth-of-type(1) .sidebar-item').exists({ count: 1 }, 'groups');
    assert.dom('.sidebar-section:nth-of-type(2) .sidebar-item').exists({ count: 2 }, 'friends');
  });

  test('typing in the filter narrows the friends list', async function (assert) {
    await render(<template><Sidebar /></template>);
    await settled();

    await fillIn('.sidebar-search', 'jane');

    assert.dom('.sidebar-section:nth-of-type(2) .sidebar-item').exists({ count: 1 });
    assert.dom('.sidebar-section:nth-of-type(2) .sidebar-item').hasText('Jane Doe');
  });

  test('sending an invite posts to the add-friend endpoint', async function (assert) {
    await render(<template><Sidebar /></template>);
    await settled();

    await fillIn('.invite-box input[type="email"]', 'new@example.com');
    await click('.invite-box button[type="submit"]');
    await settled();

    const api = this.owner.lookup('service:api');
    assert.strictEqual(api.posts.length, 1);
    assert.strictEqual(api.posts[0].body.emailId, 'new@example.com');
    assert.dom('.invite-success').exists();
  });
});
