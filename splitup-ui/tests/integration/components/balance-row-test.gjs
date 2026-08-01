import { module, test } from 'qunit';
import { setupRenderingTest } from 'splitup-ui/tests/helpers';
import { render } from '@ember/test-helpers';
import BalanceRow from 'splitup-ui/components/balance-row';

module('Integration | Component | balance-row', function (hooks) {
  setupRenderingTest(hooks);

  test('renders initials, name, and a teal amount when owed', async function (assert) {
    this.friend = { id: 3, firstName: 'Jane', lastName: 'Doe' };

    await render(
      <template>
        <BalanceRow @friend={{this.friend}} @amount={{42}} @currency="USD" />
      </template>,
    );

    assert.dom('.balance-row-avatar').hasText('JD');
    assert.dom('.balance-row-name').hasText('Jane Doe');
    assert.dom('.balance-row-amount').hasClass('text-teal');
    assert.dom('.balance-row-amount').includesText('USD 42.00');
  });

  test('renders an orange amount when you owe', async function (assert) {
    this.friend = { id: 3, firstName: 'Jane', lastName: 'Doe' };

    await render(
      <template>
        <BalanceRow @friend={{this.friend}} @amount={{-42}} @currency="USD" />
      </template>,
    );

    assert.dom('.balance-row-amount').hasClass('text-orange');
    assert.dom('.balance-row-caption').hasText('you owe');
  });

  test('links to the friend detail route', async function (assert) {
    this.friend = { id: 3, firstName: 'Jane', lastName: 'Doe' };

    await render(
      <template>
        <BalanceRow @friend={{this.friend}} @amount={{10}} @currency="USD" />
      </template>,
    );

    assert.dom('a.balance-row').exists();
  });
});
