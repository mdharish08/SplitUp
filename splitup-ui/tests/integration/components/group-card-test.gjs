import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render } from '@ember/test-helpers';
import Service from '@ember/service';
import GroupCard from 'splitup-ui/components/group-card';

class MockAuthService extends Service {
  userId = '99'; // Not a member of test groups, so balance = 0
}

module('Integration | Component | group-card', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
  });

  test('renders group name, member count, and currency', async function (assert) {
    this.group = {
      id: 5,
      name: 'Summer Trip',
      groupType: 'TRIP',
      currencyCode: 'USD',
      members: [{ id: 1 }, { id: 2 }, { id: 3 }],
    };

    await render(<template><GroupCard @group={{this.group}} /></template>);

    assert.dom('.group-list-name').hasText('Summer Trip');
    assert.dom('.group-list-meta').includesText('3 members');
    assert.dom('.group-list-meta').includesText('USD');
  });

  test('shows the group initials in the icon', async function (assert) {
    this.group = {
      id: 5,
      name: 'Summer Trip',
      currencyCode: 'USD',
      members: [],
    };

    await render(<template><GroupCard @group={{this.group}} /></template>);

    assert.dom('.group-list-icon').hasText('SU');
  });

  test('shows "settled up" badge when current user has no balance', async function (assert) {
    this.group = {
      id: 5,
      name: 'Empty Group',
      currencyCode: 'USD',
      members: [],
    };

    await render(<template><GroupCard @group={{this.group}} /></template>);

    assert.dom('.balance-badge').hasText('settled up');
    assert.dom('.balance-badge').hasClass('balance-badge--neutral');
  });

  test('shows 0 members in meta when the members array is missing', async function (assert) {
    this.group = { id: 5, name: 'Empty Group', currencyCode: 'USD' };

    await render(<template><GroupCard @group={{this.group}} /></template>);

    assert.dom('.group-list-meta').includesText('0 members');
  });

  test('root element is a link to the group detail route', async function (assert) {
    this.group = { id: 5, name: 'Trip', currencyCode: 'USD', members: [] };

    await render(<template><GroupCard @group={{this.group}} /></template>);

    assert.dom('a.group-list-row').exists();
  });
});
