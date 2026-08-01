import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render } from '@ember/test-helpers';
import BalanceBadge from 'splitup-ui/components/balance-badge';

module('Integration | Component | balance-badge', function (hooks) {
  setupRenderingTest(hooks);

  test('shows "owes you" in teal for a positive balance', async function (assert) {
    this.balance = { amount: 25.5, currency_code: 'USD' };

    await render(<template><BalanceBadge @balance={{this.balance}} /></template>);

    assert.dom('.balance-positive').hasText('owes you USD 25.50');
  });

  test('shows "you owe" in orange for a negative balance', async function (assert) {
    this.balance = { amount: -10, currency_code: 'INR' };

    await render(<template><BalanceBadge @balance={{this.balance}} /></template>);

    assert.dom('.balance-negative').hasText('you owe INR 10.00');
  });

  test('shows "settled up" for a zero balance', async function (assert) {
    this.balance = { amount: 0, currency_code: 'USD' };

    await render(<template><BalanceBadge @balance={{this.balance}} /></template>);

    assert.dom('.balance-neutral').hasText('settled up');
  });
});
