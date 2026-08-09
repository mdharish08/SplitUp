import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render } from '@ember/test-helpers';
import ExpenseItem from 'splitup-ui/components/expense-item';

module('Integration | Component | expense-item', function (hooks) {
  setupRenderingTest(hooks);

  test('shows "paid by you" label and positive share when the current user paid', async function (assert) {
    this.expense = {
      id: 1,
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

    assert.dom('.expense-row-paid-by').hasText('paid by you');
    assert.dom('.expense-row-share.expense-row-share--owed').includesText('you get back USD 50.00');
    assert.dom('.expense-row-desc').hasText('Dinner');
    assert.dom('.expense-row-amount').hasText('USD 100.00');
  });

  test('shows "paid by user N" label and negative share for a non-payer', async function (assert) {
    this.expense = {
      id: 2,
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

    assert.dom('.expense-row-paid-by').hasText('paid by user 1');
    assert.dom('.expense-row-share.expense-row-share--owe').includesText('you owe USD 50.00');
  });

  test('shows "settled" for a zero net balance', async function (assert) {
    this.expense = {
      id: 3,
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

    assert.dom('.expense-row-share').hasText('settled');
    assert.dom('.expense-row-share').doesNotHaveClass('expense-row-share--owed');
    assert.dom('.expense-row-share').doesNotHaveClass('expense-row-share--owe');
  });

  test('root element is an <a> tag (from LinkTo) for navigation', async function (assert) {
    this.expense = {
      id: 10,
      description: 'Taxi',
      cost: 20,
      currencyCode: 'USD',
      category: { categoryName: 'Transportation' },
      paidBy: 1,
      users: [{ userId: 1, netBalance: 10 }],
    };

    await render(
      <template><ExpenseItem @expense={{this.expense}} @currentUserId="1" /></template>,
    );

    assert.dom('a.expense-row').exists();
  });

  test('shows the category name in a pill', async function (assert) {
    this.expense = {
      id: 11,
      description: 'Bus fare',
      cost: 5,
      currencyCode: 'USD',
      category: { categoryName: 'Transportation' },
      paidBy: 1,
      users: [{ userId: 1, netBalance: 2.5 }],
    };

    await render(
      <template><ExpenseItem @expense={{this.expense}} @currentUserId="1" /></template>,
    );

    assert.dom('.expense-cat-pill').hasText('Transportation');
  });

  test('shows a formatted date when createdAt is provided', async function (assert) {
    this.expense = {
      id: 12,
      description: 'Coffee',
      cost: 4,
      currencyCode: 'USD',
      category: { categoryName: 'Food & Drink' },
      paidBy: 1,
      createdAt: '2025-06-15T10:00:00Z',
      users: [{ userId: 1, netBalance: 2 }],
    };

    await render(
      <template><ExpenseItem @expense={{this.expense}} @currentUserId="1" /></template>,
    );

    // The date should be formatted (not empty)
    assert.dom('.expense-row-date').hasText(/.+/);
  });

  test('shows "USD 0.00" for a zero-cost expense', async function (assert) {
    this.expense = {
      id: 13,
      description: 'Free lunch',
      cost: 0,
      currencyCode: 'USD',
      category: { categoryName: 'Other' },
      paidBy: 1,
      users: [{ userId: 1, netBalance: 0 }],
    };

    await render(
      <template><ExpenseItem @expense={{this.expense}} @currentUserId="1" /></template>,
    );

    assert.dom('.expense-row-amount').hasText('USD 0.00');
  });
});
