import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, fillIn, click, settled } from '@ember/test-helpers';
import Service from '@ember/service';
import { LoginTemplate } from 'splitup-ui/templates/login';

class MockAuthService extends Service {
  loginCalls = [];
  attemptedTransition = null;

  login(email, password) {
    this.loginCalls.push({ email, password });
    if (password === 'wrong') {
      return Promise.reject(new Error('Invalid credentials'));
    }
    return Promise.resolve();
  }
}

class MockRouterService extends Service {
  transitions = [];
  transitionTo(routeName) {
    this.transitions.push(routeName);
  }
}

module('Integration | Template | login', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:router', MockRouterService);
  });

  test('email and password fields accept typed input', async function (assert) {
    await render(<template><LoginTemplate /></template>);

    await fillIn('#email', 'me@example.com');
    await fillIn('#password', 'secret');

    assert.dom('#email').hasValue('me@example.com');
    assert.dom('#password').hasValue('secret');
  });

  test('submitting valid credentials logs in and redirects to index', async function (assert) {
    await render(<template><LoginTemplate /></template>);

    await fillIn('#email', 'me@example.com');
    await fillIn('#password', 'secret');
    await click('button[type="submit"]');

    const auth = this.owner.lookup('service:auth');
    const router = this.owner.lookup('service:router');

    assert.strictEqual(auth.loginCalls.length, 1);
    assert.strictEqual(auth.loginCalls[0].email, 'me@example.com');
    assert.strictEqual(router.transitions[0], 'index');
  });

  test('a failed login shows an error banner and does not redirect', async function (assert) {
    await render(<template><LoginTemplate /></template>);

    await fillIn('#email', 'me@example.com');
    await fillIn('#password', 'wrong');
    await click('button[type="submit"]');
    await settled();

    const router = this.owner.lookup('service:router');

    assert.dom('.error-banner').hasText('Invalid credentials');
    assert.strictEqual(router.transitions.length, 0);
  });
});
