import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, fillIn, click, triggerEvent } from '@ember/test-helpers';
import Service from '@ember/service';
import { ExpensesIndexTemplate } from 'splitup-ui/templates/expenses/index';

class MockAuthService extends Service {
  userId = '1';
  isAuthenticated = true;
}

const EXPENSE_DINNER = {
  id: 1,
  description: 'Dinner at Olive Garden',
  cost: 80,
  currencyCode: 'USD',
  category: { categoryName: 'Food & Drink' },
  paidBy: 1,
  createdAt: '2025-06-10T18:00:00Z',
  users: [{ userId: 1, netBalance: 40 }],
};

const EXPENSE_TAXI = {
  id: 2,
  description: 'Taxi to airport',
  cost: 35,
  currencyCode: 'USD',
  category: { categoryName: 'Transportation' },
  paidBy: 2,
  createdAt: '2025-06-05T09:00:00Z',
  users: [{ userId: 1, netBalance: -17.5 }],
};

module('Integration | Template | expenses/index', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
  });

  test('renders the empty state when no expenses are present', async function (assert) {
    this.model = { expenses: [] };

    await render(<template><ExpensesIndexTemplate @model={{this.model}} /></template>);

    assert.dom('.empty-state').exists();
    assert.dom('.empty-state p').hasText('No expenses yet.');
  });

  test('renders expense rows when expenses are present', async function (assert) {
    this.model = { expenses: [EXPENSE_DINNER, EXPENSE_TAXI] };

    await render(<template><ExpensesIndexTemplate @model={{this.model}} /></template>);

    assert.dom('.expense-row').exists({ count: 2 });
    assert.dom('.empty-state').doesNotExist();
  });

  test('search input filters expenses by description', async function (assert) {
    this.model = { expenses: [EXPENSE_DINNER, EXPENSE_TAXI] };

    await render(<template><ExpensesIndexTemplate @model={{this.model}} /></template>);

    assert.dom('.expense-row').exists({ count: 2 });

    await fillIn('.filter-search-wrap input', 'Dinner');
    await triggerEvent('.filter-search-wrap input', 'input');

    assert.dom('.expense-row-desc').exists({ count: 1 });
    assert.dom('.expense-row-desc').hasText('Dinner at Olive Garden');
  });

  test('category filter dropdown shows categories derived from the expenses', async function (assert) {
    this.model = { expenses: [EXPENSE_DINNER, EXPENSE_TAXI] };

    await render(<template><ExpensesIndexTemplate @model={{this.model}} /></template>);

    assert.dom('.filter-select option[value="Food & Drink"]').exists();
    assert.dom('.filter-select option[value="Transportation"]').exists();
  });

  test('"Clear filters" button appears after typing in search', async function (assert) {
    this.model = { expenses: [EXPENSE_DINNER] };

    await render(<template><ExpensesIndexTemplate @model={{this.model}} /></template>);

    await fillIn('.filter-search-wrap input', 'Din');
    await triggerEvent('.filter-search-wrap input', 'input');

    const buttons = [...document.querySelectorAll('button')];
    const clearBtn = buttons.find((b) => b.textContent.trim() === 'Clear filters');
    assert.ok(clearBtn, '"Clear filters" button is present');
  });

  test('"Clear filters" button resets the search when clicked', async function (assert) {
    this.model = { expenses: [EXPENSE_DINNER, EXPENSE_TAXI] };

    await render(<template><ExpensesIndexTemplate @model={{this.model}} /></template>);

    await fillIn('.filter-search-wrap input', 'Dinner');
    await triggerEvent('.filter-search-wrap input', 'input');

    assert.dom('.expense-row').exists({ count: 1 });

    const clearBtn = [...document.querySelectorAll('button')].find(
      (b) => b.textContent.trim() === 'Clear filters',
    );
    await click(clearBtn);

    assert.dom('.expense-row').exists({ count: 2 });
    assert.dom('.filter-search-wrap input').hasValue('');
  });

  test('sort toggle button changes between "Newest ↓" and "Oldest ↑"', async function (assert) {
    this.model = { expenses: [EXPENSE_DINNER] };

    await render(<template><ExpensesIndexTemplate @model={{this.model}} /></template>);

    const sortBtn = [...document.querySelectorAll('button')].find((b) =>
      b.textContent.includes('Newest'),
    );
    assert.ok(sortBtn, 'Sort button starts with "Newest"');
    assert.ok(sortBtn.textContent.includes('↓'), 'Starts with descending arrow');

    await click(sortBtn);

    assert.ok(sortBtn.textContent.includes('Oldest'), 'Sort button changed to "Oldest"');
    assert.ok(sortBtn.textContent.includes('↑'), 'Changed to ascending arrow');

    await click(sortBtn);

    assert.ok(sortBtn.textContent.includes('Newest'), 'Sort button toggled back to "Newest"');
  });

  test('month separator appears for grouped expenses', async function (assert) {
    this.model = { expenses: [EXPENSE_DINNER, EXPENSE_TAXI] };

    await render(<template><ExpensesIndexTemplate @model={{this.model}} /></template>);

    // Both expenses are in June 2025 → single month group with label
    assert.dom('.expense-month-group').exists({ count: 1 });
    assert.dom('.expense-month-label').hasText('JUNE 2025');
  });

  test('expenses from different months produce separate month groups', async function (assert) {
    const mayExpense = {
      id: 3,
      description: 'May coffee',
      cost: 5,
      currencyCode: 'USD',
      category: { categoryName: 'Other' },
      paidBy: 1,
      createdAt: '2025-05-20T08:00:00Z',
      users: [{ userId: 1, netBalance: 2.5 }],
    };

    this.model = { expenses: [EXPENSE_DINNER, mayExpense] };

    await render(<template><ExpensesIndexTemplate @model={{this.model}} /></template>);

    assert.dom('.expense-month-group').exists({ count: 2 });
    assert.dom('.expense-month-label').exists({ count: 2 });
  });
});
