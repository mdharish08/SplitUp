import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render } from '@ember/test-helpers';
import Service from '@ember/service';
import { FriendsFriendTemplate } from 'splitup-ui/templates/friends/friend';

class MockAuthService extends Service {
  userId = '1';
}

module('Integration | Template | friends/friend', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
  });

  test('renders friend name, email, and balance', async function (assert) {
    this.model = {
      friend: {
        id: 2,
        firstName: 'Jane',
        lastName: 'Doe',
        emailId: 'jane@example.com',
        balanceDto: { amount: 25, currency_code: 'USD' },
      },
      expenses: [],
    };

    await render(<template><FriendsFriendTemplate @model={{this.model}} /></template>);

    assert.dom('.friend-header-info h2').hasText('Jane Doe');
    assert.dom('.friend-email').hasText('jane@example.com');
    assert.dom('.balance-positive').exists();
  });

  test('renders a list of shared expenses', async function (assert) {
    this.model = {
      friend: { id: 2, firstName: 'Jane', lastName: 'Doe', emailId: 'jane@example.com' },
      expenses: [
        {
          expenseId: 1,
          description: 'Dinner',
          cost: 40,
          currencyCode: 'USD',
          category: { categoryName: 'Food & Drink' },
          paidBy: 1,
          users: [{ userId: 1, netBalance: 20 }],
        },
      ],
    };

    await render(<template><FriendsFriendTemplate @model={{this.model}} /></template>);

    assert.dom('.expense-item').exists({ count: 1 });
    assert.dom('.expense-desc').hasText('Dinner');
  });

  test('shows an empty state when there are no shared expenses', async function (assert) {
    this.model = {
      friend: { id: 2, firstName: 'Jane', lastName: 'Doe', emailId: 'jane@example.com' },
      expenses: [],
    };

    await render(<template><FriendsFriendTemplate @model={{this.model}} /></template>);

    assert.dom('.empty-state').hasText('No shared expenses yet.');
  });
});
