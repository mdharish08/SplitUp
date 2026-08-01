import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, fillIn, click } from '@ember/test-helpers';
import Service from '@ember/service';
import { GroupsNewTemplate } from 'splitup-ui/templates/groups/new';

class MockAuthService extends Service {
  userId = '1';
  userEmail = 'me@example.com';
}

class MockApiService extends Service {
  posts = [];
  post(path, body) {
    this.posts.push({ path, body });
    return Promise.resolve({ code: 0, data: { id: 42 } });
  }
}

class MockRouterService extends Service {
  transitions = [];
  transitionTo(routeName, model) {
    this.transitions.push({ routeName, model });
  }
}

const MODEL = {
  friends: [{ id: 2, firstName: 'Jane', lastName: 'Doe', emailId: 'jane@example.com' }],
};

module('Integration | Template | groups/new', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:api', MockApiService);
    this.owner.register('service:router', MockRouterService);
    this.model = MODEL;
  });

  test('name and description fields accept typed input', async function (assert) {
    await render(<template><GroupsNewTemplate @model={{this.model}} /></template>);

    await fillIn('#group-name', 'Summer Trip');
    await fillIn('#description', 'Beach house');

    assert.dom('#group-name').hasValue('Summer Trip');
    assert.dom('#description').hasValue('Beach house');
  });

  test('adding a member by email creates a chip, and it can be removed', async function (assert) {
    await render(<template><GroupsNewTemplate @model={{this.model}} /></template>);

    await fillIn('input[type="email"]', 'jane@example.com');
    await click('.input-with-btn button');

    assert.dom('.member-chip').exists({ count: 1 });
    assert.dom('.member-chip').includesText('jane@example.com');

    await click('.chip-remove');
    assert.dom('.member-chip').doesNotExist();
  });

  test('adding a member with an unknown email shows an error', async function (assert) {
    await render(<template><GroupsNewTemplate @model={{this.model}} /></template>);

    await fillIn('input[type="email"]', 'unknown@example.com');
    await click('.input-with-btn button');

    assert.dom('.error-banner').hasText('No friend found with email unknown@example.com');
    assert.dom('.member-chip').doesNotExist();
  });

  test('submitting creates the group including self and redirects to the group page', async function (assert) {
    await render(<template><GroupsNewTemplate @model={{this.model}} /></template>);

    await fillIn('#group-name', 'Summer Trip');
    await fillIn('input[type="email"]', 'jane@example.com');
    await click('.input-with-btn button');
    await click('button[type="submit"]');

    const api = this.owner.lookup('service:api');
    const router = this.owner.lookup('service:router');

    assert.strictEqual(api.posts.length, 1);
    assert.strictEqual(api.posts[0].path, '/api/v1/user/1/group');
    assert.strictEqual(api.posts[0].body.name, 'Summer Trip');
    assert.deepEqual(
      api.posts[0].body.members.map((m) => m.id).sort(),
      [1, 2],
      'includes self and the added friend',
    );
    assert.strictEqual(router.transitions[0]?.routeName, 'groups.group');
    assert.strictEqual(router.transitions[0]?.model, 42);
  });
});
