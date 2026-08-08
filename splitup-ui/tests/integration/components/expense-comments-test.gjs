import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, fillIn, click } from '@ember/test-helpers';
import Service from '@ember/service';
import ExpenseComments from 'splitup-ui/components/expense-comments';

class MockAuthService extends Service {
  userEmail = 'alice@example.com';
  isAuthenticated = true;
}

class MockApiService extends Service {
  posts = [];
  deletes = [];

  post(path, body) {
    this.posts.push({ path, body });
    return Promise.resolve({ code: 0, data: {} });
  }

  delete(path) {
    this.deletes.push(path);
    return Promise.resolve({ code: 0 });
  }
}

class MockRouterService extends Service {
  refreshes = [];

  refresh(routeName) {
    this.refreshes.push(routeName);
  }
}

class MockToastService extends Service {
  messages = [];
  success(msg) {
    this.messages.push(msg);
  }
}

module('Integration | Component | expense-comments', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:api', MockApiService);
    this.owner.register('service:router', MockRouterService);
    this.owner.register('service:toast', MockToastService);
  });

  test('renders comments and allows adding a new one', async function (assert) {
    this.comments = [
      {
        commentId: 1,
        content: 'Looks good',
        addedByName: 'Alice Smith',
        addedByEmail: 'alice@example.com',
        createdAt: '2025-06-10T18:00:00Z',
      },
    ];

    await render(
      <template><ExpenseComments @expenseId={{10}} @comments={{this.comments}} /></template>,
    );

    assert.dom('.comments-title').hasText('Comments');
    assert.dom('.comment-item').exists({ count: 1 });
    assert.dom('.comment-body').hasText('Looks good');
    assert.dom('.comment-item .btn-secondary').exists();

    await fillIn('.comments-input', 'Nice split');
    await click('.comments-form .btn-primary');

    const api = this.owner.lookup('service:api');
    const router = this.owner.lookup('service:router');
    const toast = this.owner.lookup('service:toast');

    assert.strictEqual(api.posts.length, 1);
    assert.strictEqual(api.posts[0].path, '/api/v1/expense/10/comments');
    assert.strictEqual(api.posts[0].body.content, 'Nice split');
    assert.strictEqual(router.refreshes[0], 'expenses.expense');
    assert.strictEqual(toast.messages[0], 'Comment added');
    assert.dom('.comments-input').hasValue('');
  });
});
