import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn, gt } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';
import BalanceRow from 'splitup-ui/components/balance-row';

export class IndexTemplate extends Component {
  @service auth;
  @service api;
  @service toast;
  @service router;

  @tracked showSettleModal = false;
  @tracked settleTargetFriend = null;
  @tracked settleAmount = '';
  @tracked isSettling = false;
  @tracked settleError = null;

  // ── Per-currency balance aggregation (no cross-currency addition) ──
  get friendBalances() {
    return (this.args.model.friends ?? []).map((friend) => {
      const amount = parseFloat(friend.balanceDto?.amount ?? 0) || 0;
      const currency = friend.balanceDto?.currency_code ?? 'USD';
      return { friend, amount, currency };
    });
  }

  get youOweList() {
    return this.friendBalances.filter((f) => f.amount < -0.005);
  }

  get youAreOwedList() {
    return this.friendBalances.filter((f) => f.amount > 0.005);
  }

  _sumByCurrency(items) {
    const map = {};
    for (const { amount, currency } of items) {
      map[currency] = (map[currency] ?? 0) + amount;
    }
    return Object.entries(map).map(([currency, amount]) => ({
      currency,
      amount,
      amountFormatted: amount.toFixed(2),
    }));
  }

  get youOweByCurrency() {
    return this._sumByCurrency(
      this.youOweList.map((f) => ({ amount: Math.abs(f.amount), currency: f.currency })),
    );
  }

  get youAreOwedByCurrency() {
    return this._sumByCurrency(
      this.youAreOwedList.map((f) => ({ amount: f.amount, currency: f.currency })),
    );
  }

  get netByCurrency() {
    const map = {};
    for (const { amount, currency } of this.youAreOwedList) {
      map[currency] = (map[currency] ?? 0) + amount;
    }
    for (const { amount, currency } of this.youOweList) {
      map[currency] = (map[currency] ?? 0) + amount; // negative
    }
    return Object.entries(map).map(([currency, amount]) => ({
      currency,
      amount,
      amountFormatted: amount.toFixed(2),
    }));
  }

  get settlementCategory() {
    const cats = this.args.model.categories ?? [];
    return cats.find((c) => c.categoryName === 'Other') ?? cats[0];
  }

  // ── Settle-up modal ──
  @action openSettleModal(friend) {
    this.settleTargetFriend = friend;
    this.settleAmount = Math.abs(parseFloat(friend.balanceDto?.amount ?? 0)).toFixed(2);
    this.settleError = null;
    this.showSettleModal = true;
  }

  @action closeSettleModal() {
    this.showSettleModal = false;
    this.settleTargetFriend = null;
    this.settleError = null;
  }

  @action updateSettleAmount(event) {
    this.settleAmount = event.target.value;
  }

  @action async recordSettlement(event) {
    event.preventDefault();
    this.settleError = null;
    const amount = parseFloat(this.settleAmount);
    if (!amount || amount <= 0) {
      this.settleError = 'Enter a valid amount';
      return;
    }
    if (!this.settlementCategory) {
      this.settleError = 'No category available';
      return;
    }

    const friend = this.settleTargetFriend;
    const balance = parseFloat(friend.balanceDto?.amount ?? 0);
    const owedToYou = balance > 0;
    const you = Number(this.auth.userId);
    const them = friend.id;
    const payerId = owedToYou ? them : you;
    const creditorId = owedToYou ? you : them;
    const currency = friend.balanceDto?.currency_code ?? 'USD';

    this.isSettling = true;
    try {
      const body = {
        category: this.settlementCategory,
        expenseType: 'PAYMENT',
        cost: amount,
        currencyCode: currency,
        groupId: null,
        description: 'Settle up',
        paidBy: payerId,
        users: [
          { userId: payerId, paidShare: amount, owedShare: 0, netBalance: amount },
          { userId: creditorId, paidShare: 0, owedShare: amount, netBalance: -amount },
        ],
      };
      const response = await this.api.post('/api/v1/expense', body);
      if (response?.code !== 0) throw new Error(response?.error ?? 'Failed to record payment');
      this.toast.success('Settlement recorded successfully');
      this.closeSettleModal();
      this.router.refresh('index');
    } catch (e) {
      this.settleError = e.message;
    } finally {
      this.isSettling = false;
    }
  }

  <template>
    <div class="page-content">
      {{! ── Header ── }}
      <div class="dashboard-header">
        <div>
          <p class="page-eyebrow">Overview</p>
          <h1 class="page-title">Dashboard</h1>
        </div>
        <LinkTo @route="expenses.new" class="btn-primary" style="margin-top:6px">
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M6 .5v11M.5 6h11" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
          Add expense
        </LinkTo>
      </div>

      {{! ── Balance Cards ── }}
      <div class="balance-summary">
        <div class="balance-summary-item">
          <span class="balance-summary-label">You Owe</span>
          {{#if this.youOweByCurrency.length}}
            {{#each this.youOweByCurrency as |item|}}
              <span class="balance-summary-value text-negative">{{item.currency}} {{item.amountFormatted}}</span>
            {{/each}}
          {{else}}
            <span class="balance-summary-value balance-summary-value--neutral">nothing</span>
          {{/if}}
        </div>
        <div class="balance-summary-item">
          <span class="balance-summary-label">You're Owed</span>
          {{#if this.youAreOwedByCurrency.length}}
            {{#each this.youAreOwedByCurrency as |item|}}
              <span class="balance-summary-value text-positive">{{item.currency}} {{item.amountFormatted}}</span>
            {{/each}}
          {{else}}
            <span class="balance-summary-value balance-summary-value--neutral">nothing</span>
          {{/if}}
        </div>
        <div class="balance-summary-item">
          <span class="balance-summary-label">Net Balance</span>
          {{#if this.netByCurrency.length}}
            {{#each this.netByCurrency as |item|}}
              <span class="balance-summary-value {{if (gt item.amount 0) 'text-positive' 'text-negative'}}">{{item.currency}} {{item.amountFormatted}}</span>
            {{/each}}
          {{else}}
            <span class="balance-summary-value balance-summary-value--neutral">settled up</span>
          {{/if}}
        </div>
      </div>

      {{! ── Balance Lists ── }}
      <div class="dashboard-columns">
        <div>
          <p class="column-title">You Owe</p>
          {{#if this.youOweList.length}}
            {{#each this.youOweList key="friend.id" as |item|}}
              <div class="balance-row-wrap">
                <BalanceRow @friend={{item.friend}} @amount={{item.amount}} @currency={{item.currency}} />
                <button type="button" class="settle-btn-small" {{on "click" (fn this.openSettleModal item.friend)}}>Settle</button>
              </div>
            {{/each}}
          {{else}}
            <p class="column-empty">You don't owe anyone.</p>
          {{/if}}
        </div>
        <div>
          <p class="column-title">You're Owed</p>
          {{#if this.youAreOwedList.length}}
            {{#each this.youAreOwedList key="friend.id" as |item|}}
              <div class="balance-row-wrap">
                <BalanceRow @friend={{item.friend}} @amount={{item.amount}} @currency={{item.currency}} />
                <button type="button" class="settle-btn-small" {{on "click" (fn this.openSettleModal item.friend)}}>Remind</button>
              </div>
            {{/each}}
          {{else}}
            <p class="column-empty">No one owes you anything.</p>
          {{/if}}
        </div>
      </div>

      {{#unless this.friendBalances.length}}
        <div class="empty-state">
          <p>No friends yet — add one to get started.</p>
          <LinkTo @route="friends.new" class="btn-secondary">Add a friend</LinkTo>
        </div>
      {{/unless}}

    {{! ── Settle-up modal ── }}
    {{#if this.showSettleModal}}
      <div class="modal-overlay">
        <div class="modal-card">
          <div class="modal-header">
            <h3>Settle up with {{this.settleTargetFriend.firstName}}</h3>
            <button type="button" class="modal-close" {{on "click" this.closeSettleModal}}>×</button>
          </div>
          {{#if this.settleError}}
            <div class="error-banner">{{this.settleError}}</div>
          {{/if}}
          <form {{on "submit" this.recordSettlement}}>
            <div class="form-group">
              <label>Amount ({{this.settleTargetFriend.balanceDto.currency_code}})</label>
              <input
                type="number"
                step="0.01"
                min="0.01"
                value={{this.settleAmount}}
                {{on "input" this.updateSettleAmount}}
              />
            </div>
            <div class="form-actions">
              <button type="submit" class="btn-primary" disabled={{this.isSettling}}>
                {{if this.isSettling "Recording…" "Record Payment"}}
              </button>
              <button type="button" class="btn-secondary" {{on "click" this.closeSettleModal}}>
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    {{/if}}
    </div>{{! end .page-content }}
  </template>
}

export default RouteTemplate(IndexTemplate);
