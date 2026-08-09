import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, fillIn, click, triggerEvent } from '@ember/test-helpers';
import Service from '@ember/service';
import { ExpensesNewTemplate } from 'splitup-ui/templates/expenses/new';

class MockAuthService extends Service {
  userId = '1';
  userEmail = 'me@example.com';
  isAuthenticated = true;
}

class MockApiService extends Service {
  posts = [];
  post(path, body) {
    this.posts.push({ path, body });
    return Promise.resolve({ code: 0, data: { id: 99 } });
  }
  get() {
    return Promise.resolve({ code: 0, data: [] });
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

const BASE_MODEL = {
  categories: [
    { categoryId: 1, categoryName: 'Food & Drink' },
    { categoryId: 2, categoryName: 'Transportation' },
  ],
  groups: [],
  friends: [
    { id: 2, firstName: 'Jane', lastName: 'Doe', emailId: 'jane@example.com' },
  ],
  preselectedGroupId: null,
};

module('Integration | Template | expenses/new', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:api', MockApiService);
    this.owner.register('service:router', MockRouterService);
    this.model = BASE_MODEL;
  });

  test('renders the expense form', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    assert.dom('h1').hasText('Add Expense');
    assert.dom('#expense-desc').exists();
    assert.dom('#cost').exists();
    assert.dom('#category').exists();
    assert.dom('button[type="submit"]').hasText('Add Expense');
  });

  test('EQUAL split shows a "Split equally among N people" hint', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    // EQUAL is the default split type
    await fillIn('#cost', '100');

    assert.dom('.ne-split-total-sub').containsText('among');
    assert.dom('.ne-split-total-sub').containsText('person');
  });

  test('clicking "%" button switches to PERCENTAGE mode and shows % inputs', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    await fillIn('#cost', '100');

    const pctBtn = [...document.querySelectorAll('button[type="button"]')].find(
      (b) => b.textContent.includes('Percent'),
    );
    await click(pctBtn);

    assert.dom('.share-input').exists();
    assert.dom('.split-unit').hasText('%');
    assert.dom('.ne-split-balance').containsText('100%');
  });

  test('clicking "Shares" button switches to SHARES mode', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    await fillIn('#cost', '100');

    const sharesBtn = [...document.querySelectorAll('button[type="button"]')].find(
      (b) => b.textContent.includes('Shares'),
    );
    await click(sharesBtn);

    assert.dom('.split-unit').hasText('sh');
    assert.dom('.ne-split-hint').containsText('Total shares');
  });

  test('clicking "Exact" button switches to EXACT mode and shows remaining hint', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    await fillIn('#cost', '100');

    const exactBtn = [...document.querySelectorAll('button[type="button"]')].find(
      (b) => b.textContent.includes('Exact'),
    );
    await click(exactBtn);

    assert.dom('.share-input').exists();
    assert.dom('.ne-split-balance').containsText('remaining');
  });

  test('submitting without selecting a category shows "Select a category" error', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    await fillIn('#expense-desc', 'Groceries');
    await fillIn('#cost', '50');
    // Do NOT select a category
    await click('button[type="submit"]');

    assert.dom('.error-banner').hasText('Select a category');

    const api = this.owner.lookup('service:api');
    assert.strictEqual(api.posts.length, 0, 'no API call should be made on validation error');
  });

  test('submitting a valid form posts to the API and navigates to index', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    await fillIn('#expense-desc', 'Lunch');
    await fillIn('#cost', '40');
    await fillIn('#category', '1');
    await click('button[type="submit"]');

    const api = this.owner.lookup('service:api');
    const router = this.owner.lookup('service:router');

    assert.strictEqual(api.posts.length, 1, 'one POST was made');
    assert.strictEqual(api.posts[0].path, '/api/v1/expense');
    assert.strictEqual(api.posts[0].body.description, 'Lunch');
    assert.strictEqual(api.posts[0].body.cost, 40);
    assert.strictEqual(router.transitions[0]?.routeName, 'index');
  });

  test('group context banner is shown when preselectedGroupId is set', async function (assert) {
    this.model = {
      ...BASE_MODEL,
      preselectedGroupId: '5',
      groups: [
        {
          id: 5,
          name: 'Trip to Paris',
          currencyCode: 'EUR',
          members: [
            { id: 1, firstName: 'You', lastName: '' },
            { id: 2, firstName: 'Jane', lastName: 'Doe' },
          ],
        },
      ],
    };

    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    assert.dom('.expense-group-context').exists();
    assert.dom('.expense-group-context').containsText('Trip to Paris');
  });

  test('participant list auto-populates from group members when a group is preselected', async function (assert) {
    this.model = {
      ...BASE_MODEL,
      preselectedGroupId: '5',
      groups: [
        {
          id: 5,
          name: 'Trip to Paris',
          currencyCode: 'EUR',
          members: [
            { id: 1, firstName: 'You', lastName: '' },
            { id: 2, firstName: 'Jane', lastName: 'Doe' },
          ],
        },
      ],
    };

    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    // Group member rows appear in the participant-list
    assert.dom('.participant-member-row').exists({ count: 2 });
    assert.dom('.participant-list').containsText('Jane');
  });

  test('selecting a group from the dropdown auto-populates participants', async function (assert) {
    this.model = {
      ...BASE_MODEL,
      groups: [
        {
          id: 7,
          name: 'Flatmates',
          currencyCode: 'USD',
          members: [
            { id: 1, firstName: 'You', lastName: '' },
            { id: 3, firstName: 'Chris', lastName: 'Park' },
          ],
        },
      ],
    };

    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    await fillIn('#group-select', '7');
    await triggerEvent('#group-select', 'change');

    // Payer dropdown should now include group member Chris
    assert.dom('#payer option[value="3"]').exists('group member appears as a payer option');
  });
});
