import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render } from '@ember/test-helpers';
import { IndexTemplate } from 'splitup-ui/templates/index';

module('Integration | Template | index (dashboard)', function (hooks) {
  setupRenderingTest(hooks);

  test('splits friends into YOU OWE and YOU ARE OWED columns', async function (assert) {
    this.model = {
      friends: [
        {
          id: 1,
          firstName: 'Alex',
          lastName: 'Kim',
          balanceDto: { amount: -50, currency_code: 'USD' },
          groups: [],
        },
        {
          id: 2,
          firstName: 'Sam',
          lastName: 'Lee',
          balanceDto: { amount: 30, currency_code: 'USD' },
          groups: [],
        },
      ],
    };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    assert.dom('.dashboard-column:nth-child(1) .balance-row').exists({ count: 1 });
    assert.dom('.dashboard-column:nth-child(1) .balance-row-name').hasText('Alex Kim');
    assert.dom('.dashboard-column:nth-child(2) .balance-row-name').hasText('Sam Lee');
  });

  test('combines personal and group balances into a single net amount per friend', async function (assert) {
    this.model = {
      friends: [
        {
          id: 1,
          firstName: 'Alex',
          lastName: 'Kim',
          balanceDto: { amount: -20, currency_code: 'USD' },
          groups: [{ groupId: 5, balanceDto: { amount: -30, currency_code: 'USD' } }],
        },
      ],
    };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    assert.dom('.balance-row-amount').hasText('you owe USD 50.00');
  });

  test('shows a multi-currency note when friends have different currencies', async function (assert) {
    this.model = {
      friends: [
        { id: 1, firstName: 'Alex', lastName: 'Kim', balanceDto: { amount: -10, currency_code: 'USD' }, groups: [] },
        { id: 2, firstName: 'Sam', lastName: 'Lee', balanceDto: { amount: 10, currency_code: 'INR' }, groups: [] },
      ],
    };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    assert.dom('.multi-currency-note').exists();
  });

  test('shows empty state when there are no friends', async function (assert) {
    this.model = { friends: [] };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    assert.dom('.empty-state').hasText('No friends yet. Add a friend');
    assert.dom('.column-empty').exists({ count: 2 });
  });

  test('friends settled up exactly do not appear in either column', async function (assert) {
    this.model = {
      friends: [
        { id: 1, firstName: 'Alex', lastName: 'Kim', balanceDto: { amount: 0, currency_code: 'USD' }, groups: [] },
      ],
    };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    assert.dom('.balance-row').doesNotExist();
    assert.dom('.column-empty').exists({ count: 2 });
  });
});
