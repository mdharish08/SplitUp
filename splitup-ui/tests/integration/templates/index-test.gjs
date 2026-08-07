import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, click } from '@ember/test-helpers';
import Service from '@ember/service';
import { IndexTemplate } from 'splitup-ui/templates/index';

// Do NOT mock service:router — IndexTemplate renders BalancRow which uses
// LinkTo, and LinkTo needs the real router service to generate URLs.
// We only stub the services the component uses directly for data/side-effects.

class MockAuthService extends Service {
  userId = '1';
  isAuthenticated = true;
}

class MockApiService extends Service {
  post() {
    return Promise.resolve({ code: 0, data: {} });
  }
  get() {
    return Promise.resolve({ code: 0, data: [] });
  }
}

class MockToastService extends Service {
  messages = [];
  success(msg) { this.messages.push({ type: 'success', msg }); }
  error(msg) { this.messages.push({ type: 'error', msg }); }
  info(msg) { this.messages.push({ type: 'info', msg }); }
}

const BASE_CATEGORIES = [{ categoryId: 1, categoryName: 'Other' }];

module('Integration | Template | index (dashboard)', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:api', MockApiService);
    this.owner.register('service:toast', MockToastService);
  });

  test('renders "You Owe" and "You\'re Owed" column headings', async function (assert) {
    this.model = { friends: [], categories: BASE_CATEGORIES };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    assert.dom('.column-title').exists({ count: 2 });
    assert.dom('.dashboard-columns > div:nth-child(1) .column-title').hasText('You Owe');
    assert.dom('.dashboard-columns > div:nth-child(2) .column-title').hasText("You're Owed");
  });

  test('shows "You don\'t owe anyone." when youOweList is empty', async function (assert) {
    // Only a friend who owes YOU — so the "you owe" column should be empty
    this.model = {
      friends: [
        {
          id: 2,
          firstName: 'Sam',
          lastName: 'Lee',
          balanceDto: { amount: 30, currency_code: 'USD' },
        },
      ],
      categories: BASE_CATEGORIES,
    };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    assert.dom('.dashboard-columns > div:nth-child(1) .column-empty').hasText("You don't owe anyone.");
  });

  test('shows friend name in the "You\'re Owed" balance row when they owe you', async function (assert) {
    this.model = {
      friends: [
        {
          id: 2,
          firstName: 'Sam',
          lastName: 'Lee',
          balanceDto: { amount: 30, currency_code: 'USD' },
        },
      ],
      categories: BASE_CATEGORIES,
    };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    assert.dom('.dashboard-columns > div:nth-child(2) .balance-row-name').hasText('Sam Lee');
  });

  test('shows "Add a friend" link in the empty state when friendBalances is empty', async function (assert) {
    this.model = { friends: [], categories: BASE_CATEGORIES };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    assert.dom('.empty-state').exists();
    // The LinkTo renders as an <a> tag
    assert.dom('.empty-state a').exists();
  });

  test('clicking the Settle button on a friend opens the settle modal', async function (assert) {
    this.model = {
      friends: [
        {
          id: 3,
          firstName: 'Alex',
          lastName: 'Kim',
          balanceDto: { amount: -50, currency_code: 'USD' },
        },
      ],
      categories: BASE_CATEGORIES,
    };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    assert.dom('.modal-overlay').doesNotExist();

    await click('.settle-btn-small');

    assert.dom('.modal-overlay').exists();
    assert.dom('.modal-card').exists();
  });

  test('settle modal shows the friend\'s first name in the heading', async function (assert) {
    this.model = {
      friends: [
        {
          id: 3,
          firstName: 'Alex',
          lastName: 'Kim',
          balanceDto: { amount: -50, currency_code: 'USD' },
        },
      ],
      categories: BASE_CATEGORIES,
    };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    await click('.settle-btn-small');

    assert.dom('.modal-header h3').hasText('Settle up with Alex');
  });

  test('clicking Cancel in the settle modal closes it', async function (assert) {
    this.model = {
      friends: [
        {
          id: 3,
          firstName: 'Alex',
          lastName: 'Kim',
          balanceDto: { amount: -50, currency_code: 'USD' },
        },
      ],
      categories: BASE_CATEGORIES,
    };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    await click('.settle-btn-small');
    assert.dom('.modal-overlay').exists();

    await click('.form-actions .btn-secondary');
    assert.dom('.modal-overlay').doesNotExist();
  });

  test('two friends with USD debts show a single aggregated USD total in the "you owe" summary', async function (assert) {
    this.model = {
      friends: [
        {
          id: 2,
          firstName: 'Sam',
          lastName: 'Lee',
          balanceDto: { amount: -25, currency_code: 'USD' },
        },
        {
          id: 3,
          firstName: 'Alex',
          lastName: 'Kim',
          balanceDto: { amount: -15, currency_code: 'USD' },
        },
      ],
      categories: BASE_CATEGORIES,
    };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    // The "you owe" summary section (first .balance-summary-item) aggregates by currency
    const summaryValues = document.querySelectorAll(
      '.balance-summary-item:first-child .balance-summary-value.text-negative',
    );
    assert.strictEqual(summaryValues.length, 1, 'single USD row in the you-owe summary');
    assert.ok(summaryValues[0].textContent.includes('USD'), 'shows USD currency code');
    assert.ok(summaryValues[0].textContent.includes('40.00'), 'shows combined 40.00');
  });

  test('settled friends (balance ≈ 0) do not appear in either column', async function (assert) {
    this.model = {
      friends: [
        {
          id: 4,
          firstName: 'Jordan',
          lastName: 'Park',
          balanceDto: { amount: 0, currency_code: 'USD' },
        },
      ],
      categories: BASE_CATEGORIES,
    };

    await render(<template><IndexTemplate @model={{this.model}} /></template>);

    assert.dom('.balance-row').doesNotExist();
    assert.dom('.column-empty').exists({ count: 2 });
  });
});
