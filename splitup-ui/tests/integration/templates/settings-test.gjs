import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, fillIn, click } from '@ember/test-helpers';
import Service from '@ember/service';
import { SettingsTemplate } from 'splitup-ui/templates/settings';

class MockAuthService extends Service {
  userId = '42';
  token = 'fake.token.sig';
  userEmail = 'test@example.com';
  isAuthenticated = true;
}

class MockApiService extends Service {
  puts = [];
  posts = [];

  put(path, body) {
    this.puts.push({ path, body });
    return Promise.resolve({ code: 0 });
  }

  post(path, body) {
    this.posts.push({ path, body });
    return Promise.resolve({ code: 0 });
  }
}

class MockToastService extends Service {
  messages = [];
  success(msg) { this.messages.push({ type: 'success', msg }); }
  error(msg) { this.messages.push({ type: 'error', msg }); }
  info(msg) { this.messages.push({ type: 'info', msg }); }
}

module('Integration | Template | settings', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    // Stub fetch so the constructor's loadProfile() does not make real network calls.
    this._originalFetch = window.fetch;
    window.fetch = () => Promise.reject(new Error('no network in tests'));

    this.owner.register('service:auth', MockAuthService);
    this.owner.register('service:api', MockApiService);
    this.owner.register('service:toast', MockToastService);
  });

  hooks.afterEach(function () {
    window.fetch = this._originalFetch;
  });

  test('renders "Profile" and "Change Password" section headings', async function (assert) {
    await render(<template><SettingsTemplate /></template>);

    assert.dom('.settings-section-title').exists({ count: 2 });
    assert.dom('.settings-section:nth-child(2) .settings-section-title').hasText('Profile');
    assert.dom('.settings-section:nth-child(3) .settings-section-title').hasText('Change Password');
  });

  test('email field is disabled and shows auth.userEmail', async function (assert) {
    await render(<template><SettingsTemplate /></template>);

    assert.dom('#s-email').isDisabled();
    assert.dom('#s-email').hasValue('test@example.com');
  });

  test('saving profile calls api.put with the correct endpoint', async function (assert) {
    await render(<template><SettingsTemplate /></template>);

    await fillIn('#s-first-name', 'Alice');
    await fillIn('#s-last-name', 'Smith');
    await click('.settings-section:nth-child(2) button[type="submit"]');

    const api = this.owner.lookup('service:api');
    assert.strictEqual(api.puts.length, 1);
    assert.strictEqual(api.puts[0].path, '/api/v1/user/42');
    assert.strictEqual(api.puts[0].body.firstName, 'Alice');
    assert.strictEqual(api.puts[0].body.lastName, 'Smith');
  });

  test('saving profile shows a success toast', async function (assert) {
    await render(<template><SettingsTemplate /></template>);

    await fillIn('#s-first-name', 'Alice');
    await click('.settings-section:nth-child(2) button[type="submit"]');

    const toast = this.owner.lookup('service:toast');
    assert.ok(
      toast.messages.some((m) => m.type === 'success'),
      'a success toast was shown',
    );
  });

  test('password mismatch shows "New passwords do not match" error', async function (assert) {
    await render(<template><SettingsTemplate /></template>);

    await fillIn('#s-current-pw', 'oldpassword');
    await fillIn('#s-new-pw', 'newpassword1');
    await fillIn('#s-confirm-pw', 'differentpassword');
    await click('.settings-section:nth-child(3) button[type="submit"]');

    assert.dom('.settings-section:nth-child(3) .error-banner').hasText(
      'New passwords do not match',
    );

    const api = this.owner.lookup('service:api');
    assert.strictEqual(api.posts.length, 0, 'no API call made on mismatch');
  });

  test('new password shorter than 8 characters shows a length error', async function (assert) {
    await render(<template><SettingsTemplate /></template>);

    await fillIn('#s-current-pw', 'oldpassword');
    await fillIn('#s-new-pw', 'short');
    await fillIn('#s-confirm-pw', 'short');
    await click('.settings-section:nth-child(3) button[type="submit"]');

    assert.dom('.settings-section:nth-child(3) .error-banner').hasText(
      'New password must be at least 8 characters',
    );
  });

  test('successful password change shows a success toast and clears the fields', async function (assert) {
    await render(<template><SettingsTemplate /></template>);

    await fillIn('#s-current-pw', 'oldpassword');
    await fillIn('#s-new-pw', 'newpassword1');
    await fillIn('#s-confirm-pw', 'newpassword1');
    await click('.settings-section:nth-child(3) button[type="submit"]');

    const toast = this.owner.lookup('service:toast');
    assert.ok(
      toast.messages.some((m) => m.type === 'success' && m.msg.includes('Password')),
      'success toast shown after password change',
    );

    assert.dom('#s-current-pw').hasValue('');
    assert.dom('#s-new-pw').hasValue('');
    assert.dom('#s-confirm-pw').hasValue('');
  });

  test('profile API error shows an error banner', async function (assert) {
    class FailingApiService extends Service {
      put() {
        return Promise.resolve({ code: 1, error: 'Server error' });
      }
      post() {
        return Promise.resolve({ code: 0 });
      }
    }
    this.owner.register('service:api', FailingApiService);

    await render(<template><SettingsTemplate /></template>);

    await fillIn('#s-first-name', 'Alice');
    await click('.settings-section:nth-child(2) button[type="submit"]');

    assert.dom('.settings-section:nth-child(2) .error-banner').hasText('Server error');
  });
});
