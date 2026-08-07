import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, click, fillIn } from '@ember/test-helpers';
import Service from '@ember/service';
import { FriendsFriendTemplate } from 'splitup-ui/templates/friends/friend';

class MockAuthService extends Service {
  userId = '1';
  isAuthenticated = true;
}

class MockApiService extends Service {
  posts = [];
  gets = [];
  deletes = [];

  post(path, body) {
    this.posts.push({ path, body });
    return Promise.resolve({ code: 0, data: {} });
  }

  get(path) {
    this.gets.push(path);
    return Promise.resolve({ code: 0, data: [] });
  }

  delete(path) {
    this.deletes.push(path);
    return Promise.resolve({ code: 0 });
  }
}

class MockRouterService extends Service {
  transitions = [];
  transitionTo(routeName, ...args) {
    this.transitions.push({ routeName, args });
  }
  on() {}
  off() {}
}

class MockToastService extends Service {
  messages = [];
  success(msg) { this.messages.push({ type: 'success', msg }); }
  error(msg) { this.messages.push({ type: 'error', msg }); }
}

const BASE_FRIEND = {
  id: 2,
  firstName: 'Jane',
  lastName: 'Doe',
  emailId: 'jane@example.com',
  balanceDto: { amount: 50, currency_code: 'USD' },
};

const BASE_CATEGORIES = [{ categoryId: 1, categoryName: 'Other' }];

module('Integration | Template | friends/friend', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:api', MockApiService);
    this.owner.register('service:router', MockRouterService);
    this.owner.register('service:toast', MockToastService);
  });

  test('shows friend name and email in the header', async function (assert) {
    this.model = { friend: BASE_FRIEND, expenses: [], categories: BASE_CATEGORIES };

    await render(<template><FriendsFriendTemplate @model={{this.model}} /></template>);

    assert.dom('.friend-detail-name').hasText('Jane Doe');
    assert.dom('.friend-detail-email').hasText('jane@example.com');
  });

  test('shows BalanceBadge when balanceDto is present', async function (assert) {
    this.model = { friend: BASE_FRIEND, expenses: [], categories: BASE_CATEGORIES };

    await render(<template><FriendsFriendTemplate @model={{this.model}} /></template>);

    assert.dom('.balance-positive').exists();
    assert.dom('.balance-positive').containsText('owes you');
  });

  test('"Settle up" button is visible when balance is non-zero', async function (assert) {
    this.model = { friend: BASE_FRIEND, expenses: [], categories: BASE_CATEGORIES };

    await render(<template><FriendsFriendTemplate @model={{this.model}} /></template>);

    assert.dom('.friend-detail-header-actions .btn-primary').hasText('Settle up');
  });

  test('"Settle up" button is hidden when balance is zero', async function (assert) {
    const settledFriend = {
      ...BASE_FRIEND,
      balanceDto: { amount: 0, currency_code: 'USD' },
    };
    this.model = { friend: settledFriend, expenses: [], categories: BASE_CATEGORIES };

    await render(<template><FriendsFriendTemplate @model={{this.model}} /></template>);

    assert.dom('.friend-detail-header-actions .btn-primary').doesNotExist();
  });

  test('clicking "Settle up" shows the settle form', async function (assert) {
    this.model = { friend: BASE_FRIEND, expenses: [], categories: BASE_CATEGORIES };

    await render(<template><FriendsFriendTemplate @model={{this.model}} /></template>);

    assert.dom('.form-card').doesNotExist();

    await click('.friend-detail-header-actions .btn-primary');

    assert.dom('.form-card').exists();
  });

  test('settle form has amount input pre-filled with the absolute balance', async function (assert) {
    this.model = {
      friend: { ...BASE_FRIEND, balanceDto: { amount: -30.75, currency_code: 'USD' } },
      expenses: [],
      categories: BASE_CATEGORIES,
    };

    await render(<template><FriendsFriendTemplate @model={{this.model}} /></template>);

    await click('.friend-detail-header-actions .btn-primary');

    assert.dom('#settle-amount').hasValue('30.75');
  });

  test('clicking "Settle up" a second time hides the form (toggle)', async function (assert) {
    this.model = { friend: BASE_FRIEND, expenses: [], categories: BASE_CATEGORIES };

    await render(<template><FriendsFriendTemplate @model={{this.model}} /></template>);

    await click('.friend-detail-header-actions .btn-primary'); // open
    assert.dom('.form-card').exists();

    // Button now reads "Cancel"
    assert.dom('.friend-detail-header-actions .btn-primary').hasText('Cancel');
    await click('.friend-detail-header-actions .btn-primary'); // close
    assert.dom('.form-card').doesNotExist();
  });

  test('"Remove friend" button is present', async function (assert) {
    this.model = { friend: BASE_FRIEND, expenses: [], categories: BASE_CATEGORIES };

    await render(<template><FriendsFriendTemplate @model={{this.model}} /></template>);

    assert.dom('.btn-danger').exists();
  });

  test('empty expenses list shows "No transactions yet."', async function (assert) {
    const friendNoBalance = { ...BASE_FRIEND, balanceDto: null };
    this.model = { friend: friendNoBalance, expenses: [], categories: BASE_CATEGORIES };

    await render(<template><FriendsFriendTemplate @model={{this.model}} /></template>);

    assert.dom('.empty-state p').hasText('No transactions yet.');
  });

  test('transactions are grouped by month with a separator', async function (assert) {
    const expenses = [
      {
        id: 1,
        description: 'Dinner',
        cost: 40,
        currencyCode: 'USD',
        category: { categoryName: 'Food & Drink' },
        paidBy: 1,
        createdAt: '2025-06-10T18:00:00Z',
        users: [
          { userId: 1, paidShare: 40, owedShare: 20 },
          { userId: 2, paidShare: 0, owedShare: 20 },
        ],
      },
      {
        id: 2,
        description: 'Taxi',
        cost: 20,
        currencyCode: 'USD',
        category: { categoryName: 'Transportation' },
        paidBy: 2,
        createdAt: '2025-05-05T09:00:00Z',
        users: [
          { userId: 1, paidShare: 0, owedShare: 10 },
          { userId: 2, paidShare: 20, owedShare: 10 },
        ],
      },
    ];

    this.model = { friend: BASE_FRIEND, expenses, categories: BASE_CATEGORIES };

    await render(<template><FriendsFriendTemplate @model={{this.model}} /></template>);

    assert.dom('.expense-month-group').exists({ count: 2 });
    assert.dom('.expense-month-label').exists({ count: 2 });
    assert.dom('.expense-row-desc').exists({ count: 2 });
  });
});
