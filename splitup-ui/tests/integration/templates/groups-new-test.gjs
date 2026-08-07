import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, fillIn, click, triggerEvent, settled } from '@ember/test-helpers';
import Service from '@ember/service';
import GroupForm from 'splitup-ui/components/group-form';

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

const FRIENDS = [{ id: 2, firstName: 'Jane', lastName: 'Doe', emailId: 'jane@example.com' }];

module('Integration | Template | groups/new', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:api', MockApiService);
    this.owner.register('service:router', MockRouterService);
    this.friends = FRIENDS;
  });

  test('name and description fields accept typed input', async function (assert) {
    await render(<template><GroupForm @friends={{this.friends}} /></template>);

    await fillIn('#gf-name', 'Summer Trip');
    await fillIn('#gf-desc', 'Beach house');

    assert.dom('#gf-name').hasValue('Summer Trip');
    assert.dom('#gf-desc').hasValue('Beach house');
  });

  test('currency selector defaults to USD and accepts changes', async function (assert) {
    await render(<template><GroupForm @friends={{this.friends}} /></template>);

    assert.dom('#gf-currency').hasValue('USD');
    await fillIn('#gf-currency', 'EUR');
    assert.dom('#gf-currency').hasValue('EUR');
  });

  test('searching for a friend shows them in the dropdown', async function (assert) {
    await render(<template><GroupForm @friends={{this.friends}} /></template>);

    await fillIn('.member-search-input', 'Jane');
    await triggerEvent('.member-search-input', 'input');
    await settled();

    assert.dom('.member-dropdown-item').exists({ count: 1 });
    assert.dom('.member-dropdown-name').includesText('Jane');
  });

  test('selecting a friend from the dropdown adds them to the member list', async function (assert) {
    await render(<template><GroupForm @friends={{this.friends}} /></template>);

    await fillIn('.member-search-input', 'Jane');
    await triggerEvent('.member-search-input', 'input');
    await settled();

    // Use triggerEvent mousedown to mimic how the dropdown item is selected
    await triggerEvent('.member-dropdown-item', 'mousedown');
    await settled();

    // Should have the self row + Jane's row
    assert.dom('.gf-member-row').exists({ count: 2 });
    assert.dom('.gf-member-row:not(.gf-member-row--self) .gf-member-name').includesText('Jane');
  });

  test('removing a member removes their row', async function (assert) {
    await render(<template><GroupForm @friends={{this.friends}} /></template>);

    await fillIn('.member-search-input', 'Jane');
    await triggerEvent('.member-search-input', 'input');
    await settled();
    await triggerEvent('.member-dropdown-item', 'mousedown');
    await settled();

    // Self + Jane = 2 rows
    assert.dom('.gf-member-row').exists({ count: 2 });

    await click('.gf-member-remove');
    await settled();

    // Only self row remains
    assert.dom('.gf-member-row').exists({ count: 1 });
  });

  test('submitting creates the group including self and redirects to the group page', async function (assert) {
    await render(<template><GroupForm @friends={{this.friends}} /></template>);

    await fillIn('#gf-name', 'Summer Trip');

    // Add Jane as a member
    await fillIn('.member-search-input', 'Jane');
    await triggerEvent('.member-search-input', 'input');
    await settled();
    await triggerEvent('.member-dropdown-item', 'mousedown');
    await settled();

    await click('button[type="submit"]');
    await settled();

    const api = this.owner.lookup('service:api');
    const router = this.owner.lookup('service:router');

    assert.strictEqual(api.posts.length, 1);
    assert.strictEqual(api.posts[0].path, '/api/v1/user/1/group');
    assert.strictEqual(api.posts[0].body.name, 'Summer Trip');
    assert.deepEqual(
      api.posts[0].body.members.map((m) => m.id).sort((a, b) => a - b),
      [1, 2],
      'includes self and the added friend',
    );
    assert.strictEqual(router.transitions[0]?.routeName, 'groups.group');
    assert.strictEqual(router.transitions[0]?.model, 42);
  });
});
