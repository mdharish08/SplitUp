import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render } from '@ember/test-helpers';
import { GroupsIndexTemplate } from 'splitup-ui/templates/groups/index';

module('Integration | Template | groups/index', function (hooks) {
  setupRenderingTest(hooks);

  test('renders a card for each group', async function (assert) {
    this.model = {
      groups: [
        { id: 1, name: 'Trip', groupType: 'TRIP', currencyCode: 'USD', members: [{ id: 1 }, { id: 2 }] },
        { id: 2, name: 'House', groupType: 'HOME', currencyCode: 'USD', members: [{ id: 1 }] },
      ],
    };

    await render(<template><GroupsIndexTemplate @model={{this.model}} /></template>);

    assert.dom('.group-card').exists({ count: 2 });
    assert.dom('.group-name').exists({ count: 2 });
  });

  test('shows an empty state with a create-group link when there are no groups', async function (assert) {
    this.model = { groups: [] };

    await render(<template><GroupsIndexTemplate @model={{this.model}} /></template>);

    assert.dom('.empty-state').exists();
    assert.dom('.empty-state a').hasText('Create your first group');
  });
});
