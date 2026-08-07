import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render } from '@ember/test-helpers';
import BalanceBadge from 'splitup-ui/components/balance-badge';

module('Integration | Component | balance-badge', function (hooks) {
  setupRenderingTest(hooks);

  test('positive amount shows "owes you" text and balance-positive class', async function (assert) {
    this.balance = { amount: 25.5, currency_code: 'USD' };

    await render(<template><BalanceBadge @balance={{this.balance}} /></template>);

    assert.dom('.balance-positive').exists();
    assert.dom('.balance-positive').hasText('owes you USD 25.50');
    assert.dom('.balance-negative').doesNotExist();
    assert.dom('.balance-neutral').doesNotExist();
  });

  test('negative amount shows "you owe" text and balance-negative class', async function (assert) {
    this.balance = { amount: -10, currency_code: 'INR' };

    await render(<template><BalanceBadge @balance={{this.balance}} /></template>);

    assert.dom('.balance-negative').exists();
    assert.dom('.balance-negative').hasText('you owe INR 10.00');
    assert.dom('.balance-positive').doesNotExist();
    assert.dom('.balance-neutral').doesNotExist();
  });

  test('zero amount shows "settled up" and balance-neutral class', async function (assert) {
    this.balance = { amount: 0, currency_code: 'USD' };

    await render(<template><BalanceBadge @balance={{this.balance}} /></template>);

    assert.dom('.balance-neutral').exists();
    assert.dom('.balance-neutral').hasText('settled up');
    assert.dom('.balance-positive').doesNotExist();
    assert.dom('.balance-negative').doesNotExist();
  });

  test('missing balance arg defaults to "settled up"', async function (assert) {
    await render(<template><BalanceBadge /></template>);

    assert.dom('.balance-neutral').exists();
    assert.dom('.balance-neutral').hasText('settled up');
  });

  test('large decimal amount is formatted to exactly 2 decimal places', async function (assert) {
    this.balance = { amount: 1234.5678, currency_code: 'EUR' };

    await render(<template><BalanceBadge @balance={{this.balance}} /></template>);

    assert.dom('.balance-positive').hasText('owes you EUR 1234.57');
  });

  test('small negative decimal is formatted to 2 decimal places', async function (assert) {
    this.balance = { amount: -0.5, currency_code: 'GBP' };

    await render(<template><BalanceBadge @balance={{this.balance}} /></template>);

    assert.dom('.balance-negative').hasText('you owe GBP 0.50');
  });
});
