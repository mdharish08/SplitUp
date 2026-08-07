import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render, click } from '@ember/test-helpers';
import Service from '@ember/service';
import ToastContainer from 'splitup-ui/components/toast-container';

module('Integration | Component | toast-container', function (hooks) {
  setupRenderingTest(hooks);

  test('renders nothing when toasts array is empty', async function (assert) {
    class MockToastService extends Service {
      toasts = [];
    }
    this.owner.register('service:toast', MockToastService);

    await render(<template><ToastContainer /></template>);

    assert.dom('.toast').doesNotExist();
  });

  test('renders one toast with the correct type class and message text', async function (assert) {
    class MockToastService extends Service {
      toasts = [{ id: 1, type: 'success', message: 'Profile saved!' }];
      dismiss() {}
    }
    this.owner.register('service:toast', MockToastService);

    await render(<template><ToastContainer /></template>);

    assert.dom('.toast').exists({ count: 1 });
    assert.dom('.toast--success').exists();
    assert.dom('.toast-message').hasText('Profile saved!');
  });

  test('renders multiple toasts, one per entry', async function (assert) {
    class MockToastService extends Service {
      toasts = [
        { id: 1, type: 'success', message: 'Done' },
        { id: 2, type: 'error', message: 'Oops' },
        { id: 3, type: 'info', message: 'Note' },
      ];
      dismiss() {}
    }
    this.owner.register('service:toast', MockToastService);

    await render(<template><ToastContainer /></template>);

    assert.dom('.toast').exists({ count: 3 });
    assert.dom('.toast--success').exists();
    assert.dom('.toast--error').exists();
    assert.dom('.toast--info').exists();
  });

  test('renders correct type classes for error and info toasts', async function (assert) {
    class MockToastService extends Service {
      toasts = [
        { id: 10, type: 'error', message: 'Network failure' },
        { id: 11, type: 'info', message: 'Session expiring' },
      ];
      dismiss() {}
    }
    this.owner.register('service:toast', MockToastService);

    await render(<template><ToastContainer /></template>);

    assert.dom('.toast--error .toast-message').hasText('Network failure');
    assert.dom('.toast--info .toast-message').hasText('Session expiring');
  });

  test('clicking the × button calls toast.dismiss with the correct id', async function (assert) {
    const dismissed = [];

    class MockToastService extends Service {
      toasts = [{ id: 42, type: 'info', message: 'Click to dismiss' }];
      dismiss(id) {
        dismissed.push(id);
      }
    }
    this.owner.register('service:toast', MockToastService);

    await render(<template><ToastContainer /></template>);
    await click('.toast-close');

    assert.deepEqual(dismissed, [42], 'dismiss was called with the toast id');
  });

  test('clicking × on one of multiple toasts passes the right id', async function (assert) {
    const dismissed = [];

    class MockToastService extends Service {
      toasts = [
        { id: 7, type: 'success', message: 'First' },
        { id: 8, type: 'error', message: 'Second' },
      ];
      dismiss(id) {
        dismissed.push(id);
      }
    }
    this.owner.register('service:toast', MockToastService);

    await render(<template><ToastContainer /></template>);

    // Click the close button of the second toast
    const closeButtons = document.querySelectorAll('.toast-close');
    await click(closeButtons[1]);

    assert.deepEqual(dismissed, [8], 'dismiss was called with the second toast id');
  });
});
