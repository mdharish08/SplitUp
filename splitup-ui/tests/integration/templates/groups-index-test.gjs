import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render } from '@ember/test-helpers';
import Service from '@ember/service';
import { GroupsIndexTemplate } from 'splitup-ui/templates/groups/index';

// GroupCard uses @service auth to compute the current user's balance
class MockAuthService extends Service {
  userId = '99'; // Not a member of any test group → settled up balance
}

module('Integration | Template | groups/index', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
  });

  test('renders a row for each group', async function (assert) {
    this.model = {
      groups: [
        { id: 1, name: 'Trip', groupType: 'TRIP', currencyCode: 'USD', members: [{ id: 1 }, { id: 2 }] },
        { id: 2, name: 'House', groupType: 'HOME', currencyCode: 'USD', members: [{ id: 1 }] },
      ],
    };

    await render(<template><GroupsIndexTemplate @model={{this.model}} /></template>);

    assert.dom('.group-list-row').exists({ count: 2 });
    assert.dom('.group-list-name').exists({ count: 2 });
  });

  test('group rows display the correct group name', async function (assert) {
    this.model = {
      groups: [
        { id: 1, name: 'Summer Trip', currencyCode: 'USD', members: [] },
      ],
    };

    await render(<template><GroupsIndexTemplate @model={{this.model}} /></template>);

    assert.dom('.group-list-name').hasText('Summer Trip');
  });

  test('shows an empty state with a create-group link when there are no groups', async function (assert) {
    this.model = { groups: [] };

    await render(<template><GroupsIndexTemplate @model={{this.model}} /></template>);

    assert.dom('.empty-state').exists();
    assert.dom('.empty-state a').hasText('Create your first group');
  });
});
