import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, fillIn, click } from '@ember/test-helpers';
import Service from '@ember/service';
import { FriendsNewTemplate } from 'splitup-ui/templates/friends/new';

class MockAuthService extends Service {
  userId = '1';
}

class MockApiService extends Service {
  posts = [];
  post(path, body) {
    this.posts.push({ path, body });
    return Promise.resolve({ code: 0, data: { id: 7 } });
  }
}

class MockRouterService extends Service {
  transitions = [];
  transitionTo(routeName, model) {
    this.transitions.push({ routeName, model });
  }
}

module('Integration | Template | friends/new', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:api', MockApiService);
    this.owner.register('service:router', MockRouterService);
  });

  test('the email field accepts typed input', async function (assert) {
    await render(<template><FriendsNewTemplate /></template>);

    await fillIn('#friend-email', 'jane@example.com');

    assert.dom('#friend-email').hasValue('jane@example.com');
  });

  test('changing the currency select updates the value', async function (assert) {
    await render(<template><FriendsNewTemplate /></template>);

    await fillIn('#friend-currency', 'INR');

    assert.dom('#friend-currency').hasValue('INR');
  });

  test('submitting posts to the add-friend endpoint and redirects to the friend page', async function (assert) {
    await render(<template><FriendsNewTemplate /></template>);

    await fillIn('#friend-email', 'jane@example.com');
    await fillIn('#friend-currency', 'INR');
    await click('button[type="submit"]');

    const api = this.owner.lookup('service:api');
    const router = this.owner.lookup('service:router');

    assert.strictEqual(api.posts.length, 1);
    assert.strictEqual(api.posts[0].path, '/api/v1/friends/1');
    assert.strictEqual(api.posts[0].body.emailId, 'jane@example.com');
    assert.strictEqual(api.posts[0].body.currencyCode, 'INR');
    assert.strictEqual(router.transitions[0]?.routeName, 'friends.friend');
    assert.strictEqual(router.transitions[0]?.model, 7);
  });

  test('a failed add-friend request shows an error banner', async function (assert) {
    class FailingApiService extends Service {
      post() {
        return Promise.resolve({ code: 1, error: 'Already friends' });
      }
    }
    this.owner.register('service:api', FailingApiService);

    await render(<template><FriendsNewTemplate /></template>);

    await fillIn('#friend-email', 'jane@example.com');
    await click('button[type="submit"]');

    assert.dom('.error-banner').hasText('Already friends');
  });
});
