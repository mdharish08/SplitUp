import { module, test } from 'qunit';
import { setupTest } from 'splitup-ui/tests/helpers';

// Build a minimal base64url-encoded JWT with the given payload.
// The auth service only looks at token.split('.')[1] and JSON.parse(atob(segment)).
function makeFakeJwt(payload) {
  const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const body = btoa(JSON.stringify(payload));
  return `${header}.${body}.fakesig`;
}

module('Unit | Service | auth', function (hooks) {
  setupTest(hooks);

  hooks.beforeEach(function () {
    // Remove any tokens left by previous tests before the service is instantiated.
    localStorage.removeItem('splitup_token');
    localStorage.removeItem('splitup_userId');
    localStorage.removeItem('splitup_email');
  });

  hooks.afterEach(function () {
    localStorage.removeItem('splitup_token');
    localStorage.removeItem('splitup_userId');
    localStorage.removeItem('splitup_email');
  });

  test('isAuthenticated returns false when no token', function (assert) {
    const auth = this.owner.lookup('service:auth');
    auth.token = null;
    assert.false(auth.isAuthenticated);
  });

  test('isAuthenticated returns false for an expired token (exp in the past)', function (assert) {
    const auth = this.owner.lookup('service:auth');
    const expiredToken = makeFakeJwt({
      userId: 1,
      sub: 'a@b.com',
      exp: Math.floor(Date.now() / 1000) - 3600,
    });
    auth.token = expiredToken;
    assert.false(auth.isAuthenticated);
  });

  test('isAuthenticated returns true for a valid token (exp in the future)', function (assert) {
    const auth = this.owner.lookup('service:auth');
    const validToken = makeFakeJwt({
      userId: 1,
      sub: 'a@b.com',
      exp: Math.floor(Date.now() / 1000) + 3600,
    });
    auth.token = validToken;
    assert.true(auth.isAuthenticated);
  });

  test('logout() clears token, userId, and userEmail on the service and in localStorage', function (assert) {
    const auth = this.owner.lookup('service:auth');
    const validToken = makeFakeJwt({
      userId: 1,
      sub: 'a@b.com',
      exp: Math.floor(Date.now() / 1000) + 3600,
    });

    auth.token = validToken;
    auth.userId = '1';
    auth.userEmail = 'a@b.com';
    localStorage.setItem('splitup_token', validToken);
    localStorage.setItem('splitup_userId', '1');
    localStorage.setItem('splitup_email', 'a@b.com');

    auth.logout();

    assert.strictEqual(auth.token, null, 'service token is null');
    assert.strictEqual(auth.userId, null, 'service userId is null');
    assert.strictEqual(auth.userEmail, null, 'service userEmail is null');
    assert.strictEqual(localStorage.getItem('splitup_token'), null, 'localStorage token removed');
    assert.strictEqual(localStorage.getItem('splitup_userId'), null, 'localStorage userId removed');
    assert.strictEqual(localStorage.getItem('splitup_email'), null, 'localStorage email removed');
  });

  test('tokenExpiresAt returns null when no token', function (assert) {
    const auth = this.owner.lookup('service:auth');
    auth.token = null;
    assert.strictEqual(auth.tokenExpiresAt, null);
  });

  test('tokenExpiresAt returns the exp timestamp in milliseconds for a valid token', function (assert) {
    const auth = this.owner.lookup('service:auth');
    const expSec = Math.floor(Date.now() / 1000) + 3600;
    const validToken = makeFakeJwt({ userId: 1, sub: 'a@b.com', exp: expSec });
    auth.token = validToken;
    assert.strictEqual(auth.tokenExpiresAt, expSec * 1000);
  });

  test('isNearExpiry returns false when exp is more than 5 minutes away', function (assert) {
    const auth = this.owner.lookup('service:auth');
    const validToken = makeFakeJwt({
      userId: 1,
      sub: 'a@b.com',
      exp: Math.floor(Date.now() / 1000) + 3600, // 1 hour from now
    });
    auth.token = validToken;
    assert.false(auth.isNearExpiry);
  });

  test('isNearExpiry returns true when exp is less than 5 minutes away', function (assert) {
    const auth = this.owner.lookup('service:auth');
    const validToken = makeFakeJwt({
      userId: 1,
      sub: 'a@b.com',
      exp: Math.floor(Date.now() / 1000) + 60, // 1 minute from now
    });
    auth.token = validToken;
    assert.true(auth.isNearExpiry);
  });
});
