import { module, test } from 'qunit';
import { setupTest } from 'splitup-ui/tests/helpers';

module('Unit | Service | toast', function (hooks) {
  setupTest(hooks);

  test('toasts array starts empty', function (assert) {
    const service = this.owner.lookup('service:toast');
    assert.deepEqual(service.toasts, []);
  });

  test('success() adds a toast with type "success" and the given message', function (assert) {
    const service = this.owner.lookup('service:toast');
    service.success('Everything is fine');
    assert.strictEqual(service.toasts.length, 1);
    assert.strictEqual(service.toasts[0].type, 'success');
    assert.strictEqual(service.toasts[0].message, 'Everything is fine');
  });

  test('error() adds a toast with type "error"', function (assert) {
    const service = this.owner.lookup('service:toast');
    service.error('Something broke');
    assert.strictEqual(service.toasts.length, 1);
    assert.strictEqual(service.toasts[0].type, 'error');
    assert.strictEqual(service.toasts[0].message, 'Something broke');
  });

  test('info() adds a toast with type "info"', function (assert) {
    const service = this.owner.lookup('service:toast');
    service.info('Just so you know');
    assert.strictEqual(service.toasts.length, 1);
    assert.strictEqual(service.toasts[0].type, 'info');
    assert.strictEqual(service.toasts[0].message, 'Just so you know');
  });

  test('dismiss(id) removes the toast with that id', function (assert) {
    const service = this.owner.lookup('service:toast');
    service.success('first');
    service.success('second');
    assert.strictEqual(service.toasts.length, 2);

    const idToRemove = service.toasts[0].id;
    service.dismiss(idToRemove);

    assert.strictEqual(service.toasts.length, 1);
    assert.notEqual(service.toasts[0].id, idToRemove);
  });

  test('dismiss(id) is a no-op when the id does not exist', function (assert) {
    const service = this.owner.lookup('service:toast');
    service.success('hello');
    service.dismiss(99999);
    assert.strictEqual(service.toasts.length, 1);
  });

  test('calling success() twice gives two toasts with distinct ids', function (assert) {
    const service = this.owner.lookup('service:toast');
    service.success('first');
    service.success('second');
    assert.strictEqual(service.toasts.length, 2);
    assert.notStrictEqual(service.toasts[0].id, service.toasts[1].id);
  });
});
