import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, fillIn, click } from '@ember/test-helpers';
import Service from '@ember/service';
import { SignupTemplate } from 'splitup-ui/templates/signup';

class MockRouterService extends Service {
  transitions = [];
  transitionTo(routeName) {
    this.transitions.push(routeName);
  }
}

module('Integration | Template | signup', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:router', MockRouterService);
  });

  test('all fields accept typed input', async function (assert) {
    await render(<template><SignupTemplate /></template>);

    await fillIn('#firstName', 'Jane');
    await fillIn('#lastName', 'Doe');
    await fillIn('#emailId', 'jane@example.com');
    await fillIn('#password', 'secret123');

    assert.dom('#firstName').hasValue('Jane');
    assert.dom('#lastName').hasValue('Doe');
    assert.dom('#emailId').hasValue('jane@example.com');
    assert.dom('#password').hasValue('secret123');
  });

  test('submitting posts to /api/v1/signup and redirects to login on success', async function (assert) {
    const originalFetch = window.fetch;
    let capturedBody = null;
    window.fetch = (url, options) => {
      capturedBody = JSON.parse(options.body);
      return Promise.resolve({
        json: () => Promise.resolve({ code: 0, data: { id: 1 } }),
      });
    };

    try {
      await render(<template><SignupTemplate /></template>);

      await fillIn('#firstName', 'Jane');
      await fillIn('#lastName', 'Doe');
      await fillIn('#emailId', 'jane@example.com');
      await fillIn('#password', 'secret123');
      await click('button[type="submit"]');

      const router = this.owner.lookup('service:router');
      assert.strictEqual(capturedBody.emailId, 'jane@example.com');
      assert.strictEqual(router.transitions[0], 'login');
    } finally {
      window.fetch = originalFetch;
    }
  });

  test('a failed signup shows an error banner', async function (assert) {
    const originalFetch = window.fetch;
    window.fetch = () =>
      Promise.resolve({
        json: () => Promise.resolve({ code: 1, error: 'Email already registered' }),
      });

    try {
      await render(<template><SignupTemplate /></template>);

      await fillIn('#firstName', 'Jane');
      await fillIn('#emailId', 'jane@example.com');
      await fillIn('#password', 'secret123');
      await click('button[type="submit"]');

      assert.dom('.error-banner').hasText('Email already registered');
    } finally {
      window.fetch = originalFetch;
    }
  });
});
