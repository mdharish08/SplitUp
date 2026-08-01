import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, fillIn, click } from '@ember/test-helpers';
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
}

const MODEL = {
  categories: [
    { categoryId: 1, categoryName: 'Food & Drink' },
    { categoryId: 2, categoryName: 'Transportation' },
  ],
  groups: [],
  friends: [
    { id: 2, firstName: 'Jane', lastName: 'Doe', emailId: 'jane@example.com' },
  ],
};

module('Integration | Template | expenses/new', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:api', MockApiService);
    this.owner.register('service:router', MockRouterService);
    this.model = MODEL;
  });

  test('the description field accepts typed input', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    await fillIn('#expense-desc', 'Dinner at Olive Garden');

    assert.dom('#expense-desc').hasValue('Dinner at Olive Garden');
  });

  test('the amount field accepts typed input', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    await fillIn('#cost', '250');

    assert.dom('#cost').hasValue('250');
  });

  test('selecting a category updates the select value', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    await fillIn('#category', '2');

    assert.dom('#category').hasValue('2');
  });

  test('checking a friend adds them as a participant and to the payer list', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    assert.dom('[data-test-participant-checkbox="2"]').isNotChecked();

    await click('[data-test-participant-checkbox="2"]');

    assert.dom('[data-test-participant-checkbox="2"]').isChecked();
    assert.dom('#payer option[value="2"]').exists('friend appears as a payer option');
  });

  test('unchecking a friend removes them from participants', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    await click('[data-test-participant-checkbox="2"]');
    await click('[data-test-participant-checkbox="2"]');

    assert.dom('[data-test-participant-checkbox="2"]').isNotChecked();
    assert.dom('#payer option[value="2"]').doesNotExist();
  });

  test('exact split mode allows typing a per-person share without losing focus', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    await fillIn('#cost', '100');
    await click('[data-test-participant-checkbox="2"]');
    await click('[data-test-split-exact]');

    const input = document.querySelector('[data-test-share-input="2"]');
    await fillIn(input, '4');
    assert.strictEqual(document.activeElement, input, 'input keeps focus after first digit');

    await fillIn(input, '40');
    assert.strictEqual(document.activeElement, input, 'input keeps focus after second digit');
    assert.dom('[data-test-share-input="2"]').hasValue('40');
  });

  test('submitting a valid personal expense posts to the API and transitions to index', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    await fillIn('#expense-desc', 'Groceries');
    await fillIn('#cost', '100');
    await fillIn('#category', '1');
    await click('button[type="submit"]');

    const api = this.owner.lookup('service:api');
    const router = this.owner.lookup('service:router');

    assert.strictEqual(api.posts.length, 1, 'one POST was made');
    assert.strictEqual(api.posts[0].path, '/api/v1/expense');
    assert.strictEqual(api.posts[0].body.description, 'Groceries');
    assert.strictEqual(api.posts[0].body.cost, 100);
    assert.strictEqual(router.transitions[0]?.routeName, 'index');
  });

  test('submitting without a category shows an error and does not call the API', async function (assert) {
    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);

    await fillIn('#expense-desc', 'Groceries');
    await fillIn('#cost', '100');
    await click('button[type="submit"]');

    const api = this.owner.lookup('service:api');
    assert.strictEqual(api.posts.length, 0, 'no POST was made');
    assert.dom('.error-banner').hasText('Select a category');
  });

  test('selecting a group auto-populates participants from group members', async function (assert) {
    this.model = {
      ...MODEL,
      groups: [
        {
          id: 5,
          name: 'Trip',
          members: [
            { id: 1, firstName: 'You', lastName: '' },
            { id: 3, firstName: 'Alex', lastName: 'Kim' },
          ],
        },
      ],
    };

    await render(<template><ExpensesNewTemplate @model={{this.model}} /></template>);
    await fillIn('#group-select', '5');

    assert.dom('#payer option[value="3"]').exists('group member appears as payer option');
  });
});
