import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render } from '@ember/test-helpers';
import GroupCard from 'splitup-ui/components/group-card';

module('Integration | Component | group-card', function (hooks) {
  setupRenderingTest(hooks);

  test('renders group name, type, currency, and member count', async function (assert) {
    this.group = {
      id: 5,
      name: 'Summer Trip',
      groupType: 'TRIP',
      currencyCode: 'USD',
      members: [{ id: 1 }, { id: 2 }, { id: 3 }],
    };

    await render(<template><GroupCard @group={{this.group}} /></template>);

    assert.dom('.group-name').hasText('Summer Trip');
    assert.dom('.group-members').hasText('3 members');
    assert.dom('.badge').exists({ count: 2 });
  });

  test('shows 0 members when the members array is missing', async function (assert) {
    this.group = { id: 5, name: 'Empty Group' };

    await render(<template><GroupCard @group={{this.group}} /></template>);

    assert.dom('.group-members').hasText('0 members');
  });
});
