import Component from '@glimmer/component';
import { LinkTo } from '@ember/routing';
import { gt } from '@ember/helper';
import RouteTemplate from 'ember-route-template';
import BalanceRow from 'splitup-ui/components/balance-row';

export class IndexTemplate extends Component {
  get friendBalances() {
    return (this.args.model.friends ?? []).map((friend) => {
      const personal = friend.balanceDto?.amount ? parseFloat(friend.balanceDto.amount) : 0;
      const personalCurrency = friend.balanceDto?.currency_code;
      let groupTotal = 0;
      let groupCurrency = null;
      (friend.groups ?? []).forEach((g) => {
        if (g.balanceDto?.amount) {
          groupTotal += parseFloat(g.balanceDto.amount);
          groupCurrency = groupCurrency || g.balanceDto.currency_code;
        }
      });
      return {
        friend,
        amount: personal + groupTotal,
        currency: personalCurrency || groupCurrency || 'USD',
      };
    });
  }

  get youOweList() {
    return this.friendBalances.filter((f) => f.amount < -0.005);
  }

  get youAreOwedList() {
    return this.friendBalances.filter((f) => f.amount > 0.005);
  }

  get totalYouOwe() {
    return this.youOweList.reduce((sum, f) => sum + Math.abs(f.amount), 0);
  }

  get totalYouAreOwed() {
    return this.youAreOwedList.reduce((sum, f) => sum + f.amount, 0);
  }

  get totalBalance() {
    return this.totalYouAreOwed - this.totalYouOwe;
  }

  get hasMultipleCurrencies() {
    return new Set(this.friendBalances.map((f) => f.currency)).size > 1;
  }

  get dominantCurrency() {
    return this.friendBalances[0]?.currency ?? 'USD';
  }

  <template>
    <div class="dashboard-header">
      <h2>Dashboard</h2>
      <div class="dashboard-actions">
        <LinkTo @route="expenses.new" class="btn-orange">Add an expense</LinkTo>
        <LinkTo @route="expenses.new" class="btn-outline-teal">Settle up</LinkTo>
      </div>
    </div>

    <div class="balance-summary">
      <div class="balance-summary-item">
        <span class="balance-summary-label">total balance</span>
        <span class="balance-summary-value {{if (gt this.totalBalance 0) 'text-teal' 'text-orange'}}">
          {{this.dominantCurrency}}
          {{this.totalBalance}}
        </span>
      </div>
      <div class="balance-summary-item">
        <span class="balance-summary-label">you owe</span>
        <span class="balance-summary-value text-orange">
          {{this.dominantCurrency}}
          {{this.totalYouOwe}}
        </span>
      </div>
      <div class="balance-summary-item">
        <span class="balance-summary-label">you are owed</span>
        <span class="balance-summary-value text-teal">
          {{this.dominantCurrency}}
          {{this.totalYouAreOwed}}
        </span>
      </div>
    </div>

    {{#if this.hasMultipleCurrencies}}
      <p class="multi-currency-note">* You have balances in multiple currencies.</p>
    {{/if}}

    <div class="dashboard-columns">
      <div class="dashboard-column">
        <h3 class="column-title">YOU OWE</h3>
        {{#if this.youOweList.length}}
          {{#each this.youOweList key="friend.id" as |item|}}
            <BalanceRow @friend={{item.friend}} @amount={{item.amount}} @currency={{item.currency}} />
          {{/each}}
        {{else}}
          <p class="column-empty">You don't owe anyone.</p>
        {{/if}}
      </div>
      <div class="dashboard-column">
        <h3 class="column-title">YOU ARE OWED</h3>
        {{#if this.youAreOwedList.length}}
          {{#each this.youAreOwedList key="friend.id" as |item|}}
            <BalanceRow @friend={{item.friend}} @amount={{item.amount}} @currency={{item.currency}} />
          {{/each}}
        {{else}}
          <p class="column-empty">No one owes you anything.</p>
        {{/if}}
      </div>
    </div>

    {{#unless this.friendBalances.length}}
      <div class="empty-state">
        <p>No friends yet.</p>
        <LinkTo @route="friends.new" class="btn-secondary">Add a friend</LinkTo>
      </div>
    {{/unless}}
  </template>
}

export default RouteTemplate(IndexTemplate);
