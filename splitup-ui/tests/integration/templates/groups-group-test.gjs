import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render } from '@ember/test-helpers';
import Service from '@ember/service';
import { GroupsGroupTemplate } from 'splitup-ui/templates/groups/group';

class MockAuthService extends Service {
  userId = '1';
}

class MockApiService extends Service {
  get() { return Promise.resolve({ code: 0, data: [] }); }
  post() { return Promise.resolve({ code: 0, data: {} }); }
  put() { return Promise.resolve({ code: 0 }); }
  delete() { return Promise.resolve({ code: 0 }); }
}

class MockRouterService extends Service {
  transitionTo() {}
  on() {}
  off() {}
}

module('Integration | Template | groups/group', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:api', MockApiService);
    this.owner.register('service:router', MockRouterService);
  });

  test('renders group name and member meta in the header', async function (assert) {
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

    assert.dom('.group-detail-name').hasText('Summer Trip');
    assert.dom('.group-detail-meta').includesText('2 members');
    assert.dom('.group-detail-meta').includesText('USD');
  });

  test('renders member rows in the member panel', async function (assert) {
    this.model = {
      group: {
        name: 'Summer Trip',
        currencyCode: 'USD',
        members: [
          { id: 1, firstName: 'You', lastName: '' },
          { id: 2, firstName: 'Jane', lastName: 'Doe' },
        ],
      },
      expenses: [],
    };

    await render(<template><GroupsGroupTemplate @model={{this.model}} /></template>);

    assert.dom('.group-member-row').exists({ count: 2 });
  });

  test('renders the group expense list', async function (assert) {
    this.model = {
      group: { name: 'Trip', currencyCode: 'USD', members: [] },
      expenses: [
        {
          id: 1,
          description: 'Hotel',
          cost: 200,
          currencyCode: 'USD',
          category: { categoryName: 'Rent' },
          paidBy: 1,
          createdAt: '2025-06-10T12:00:00Z',
          users: [{ userId: 1, paidShare: 200, owedShare: 100 }],
        },
      ],
    };

    await render(<template><GroupsGroupTemplate @model={{this.model}} /></template>);

    assert.dom('.expense-row').exists({ count: 1 });
    assert.dom('.expense-row-desc').hasText('Hotel');
  });

  test('shows an empty state when there are no expenses', async function (assert) {
    this.model = { group: { name: 'Trip', currencyCode: 'USD', members: [] }, expenses: [] };

    await render(<template><GroupsGroupTemplate @model={{this.model}} /></template>);

    assert.dom('.empty-state').exists();
    assert.dom('.empty-state p').hasText('No expenses yet.');
  });
});
