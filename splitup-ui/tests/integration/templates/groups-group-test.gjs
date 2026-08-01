import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render } from '@ember/test-helpers';
import Service from '@ember/service';
import { GroupsGroupTemplate } from 'splitup-ui/templates/groups/group';

class MockAuthService extends Service {
  userId = '1';
}

module('Integration | Template | groups/group', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
  });

  test('renders group name, type, currency, and members', async function (assert) {
    this.model = {
      group: {
        name: 'Summer Trip',
        groupType: 'TRIP',
        currencyCode: 'USD',
        description: 'Beach house',
        members: [
          { id: 1, firstName: 'You', lastName: '', email: 'me@example.com' },
          { id: 2, firstName: 'Jane', lastName: 'Doe', email: 'jane@example.com' },
        ],
      },
      expenses: [],
    };

    await render(<template><GroupsGroupTemplate @model={{this.model}} /></template>);

    assert.dom('.group-header h2').hasText('Summer Trip');
    assert.dom('.group-meta-detail').includesText('TRIP');
    assert.dom('.group-description').hasText('Beach house');
    assert.dom('.member-card').exists({ count: 2 });
  });

  test('renders the group expense list', async function (assert) {
    this.model = {
      group: { name: 'Trip', members: [] },
      expenses: [
        {
          expenseId: 1,
          description: 'Hotel',
          cost: 200,
          currencyCode: 'USD',
          category: { categoryName: 'Rent' },
          paidBy: 1,
          users: [{ userId: 1, netBalance: 100 }],
        },
      ],
    };

    await render(<template><GroupsGroupTemplate @model={{this.model}} /></template>);

    assert.dom('.expense-item').exists({ count: 1 });
    assert.dom('.expense-desc').hasText('Hotel');
  });

  test('shows an empty state when there are no expenses', async function (assert) {
    this.model = { group: { name: 'Trip', members: [] }, expenses: [] };

    await render(<template><GroupsGroupTemplate @model={{this.model}} /></template>);

    assert.dom('.empty-state').hasText('No expenses yet.');
  });
});
