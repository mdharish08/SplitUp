import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render } from '@ember/test-helpers';
import ExpenseItem from 'splitup-ui/components/expense-item';

module('Integration | Component | expense-item', function (hooks) {
  setupRenderingTest(hooks);

  test('shows "you paid" badge and a positive net balance when the current user paid', async function (assert) {
    this.expense = {
      description: 'Dinner',
      cost: 100,
      currencyCode: 'USD',
      category: { categoryName: 'Food & Drink' },
      paidBy: 1,
      users: [
        { userId: 1, netBalance: 50 },
        { userId: 2, netBalance: -50 },
      ],
    };

    await render(
      <template><ExpenseItem @expense={{this.expense}} @currentUserId="1" /></template>,
    );

    assert.dom('.badge-paid').hasText('you paid');
    assert.dom('.balance-positive').hasText('+50.00');
    assert.dom('.expense-desc').hasText('Dinner');
    assert.dom('.expense-amount').hasText('USD 100.00');
  });

  test('shows a negative net balance and no "you paid" badge for a non-payer', async function (assert) {
    this.expense = {
      description: 'Dinner',
      cost: 100,
      currencyCode: 'USD',
      category: { categoryName: 'Food & Drink' },
      paidBy: 1,
      users: [
        { userId: 1, netBalance: 50 },
        { userId: 2, netBalance: -50 },
      ],
    };

    await render(
      <template><ExpenseItem @expense={{this.expense}} @currentUserId="2" /></template>,
    );

    assert.dom('.badge-paid').doesNotExist();
    assert.dom('.balance-negative').hasText('-50.00');
  });

  test('shows "even" for a zero net balance', async function (assert) {
    this.expense = {
      description: 'Split evenly',
      cost: 100,
      currencyCode: 'USD',
      category: { categoryName: 'Other' },
      paidBy: 1,
      users: [{ userId: 1, netBalance: 0 }],
    };

    await render(
      <template><ExpenseItem @expense={{this.expense}} @currentUserId="1" /></template>,
    );

    assert.dom('.balance-neutral').hasText('even');
  });
});
