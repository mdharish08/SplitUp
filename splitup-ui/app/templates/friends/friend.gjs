import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';
import BalanceBadge from 'splitup-ui/components/balance-badge';

export class FriendsFriendTemplate extends Component {
  @service auth;
  @service api;

  @tracked friend = this.args.model.friend;
  @tracked expenses = this.args.model.expenses;
  @tracked showSettleForm = false;
  @tracked settleAmount = '';
  @tracked isSettling = false;
  @tracked settleError = null;

  get balanceAmount() {
    return parseFloat(this.friend?.balanceDto?.amount ?? 0);
  }

  get currencyCode() {
    return this.friend?.balanceDto?.currency_code ?? 'USD';
  }

  get owedToYou() {
    return this.balanceAmount > 0;
  }

  get settlementCategory() {
    const categories = this.args.model.categories ?? [];
    return categories.find((c) => c.categoryName === 'Other') ?? categories[0];
  }

  // Unified, date-sorted timeline grouped by month
  get groupedExpenses() {
    const userId = String(this.auth.userId);
    const sorted = [...(this.expenses ?? [])].sort(
      (a, b) => new Date(b.createdAt) - new Date(a.createdAt),
    );

    const groups = [];
    let cur = null;

    for (const exp of sorted) {
      const d = new Date(exp.createdAt);
      const key = `${d.getFullYear()}-${d.getMonth()}`;
      const label = d
        .toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
        .toUpperCase();

      const mySplit = exp.users?.find((u) => String(u.userId) === userId);
      let myShareLabel = 'not involved';
      let myShareType = 'neutral';
      if (mySplit) {
        const paid = parseFloat(mySplit.paidShare ?? 0) || 0;
        const owed = parseFloat(mySplit.owedShare ?? 0) || 0;
        const currency = exp.currencyCode ?? '';
        if (paid > 0) {
          myShareLabel = `you paid ${currency} ${parseFloat(exp.cost ?? 0).toFixed(2)}`.trim();
          myShareType = 'positive';
        } else if (owed > 0) {
          myShareLabel = `you owe ${currency} ${owed.toFixed(2)}`.trim();
          myShareType = 'negative';
        }
      }

      const enriched = {
        ...exp,
        myShareLabel,
        myShareType,
        dayNum: d.getDate(),
        monthShort: d.toLocaleDateString('en-US', { month: 'short' }).toUpperCase(),
        formattedCost: `${exp.currencyCode ?? ''} ${parseFloat(exp.cost ?? 0).toFixed(2)}`.trim(),
      };

      if (!cur || cur.key !== key) {
        cur = { key, label, items: [] };
        groups.push(cur);
      }
      cur.items.push(enriched);
    }

    return groups;
  }

  @action toggleSettleForm() {
    this.showSettleForm = !this.showSettleForm;
    this.settleError = null;
    if (this.showSettleForm) {
      this.settleAmount = Math.abs(this.balanceAmount).toFixed(2);
    }
  }

  @action updateSettleAmount(event) {
    this.settleAmount = event.target.value;
  }

  @action async recordSettlement(event) {
    event.preventDefault();
    this.settleError = null;

    const amount = parseFloat(this.settleAmount);
    if (!amount || amount <= 0) {
      this.settleError = 'Enter an amount greater than zero';
      return;
    }
    if (!this.settlementCategory) {
      this.settleError = 'No category available to record this payment';
      return;
    }

    const you = Number(this.auth.userId);
    const them = this.friend.id;
    const payerId = this.owedToYou ? them : you;
    const creditorId = this.owedToYou ? you : them;

    this.isSettling = true;
    try {
      const body = {
        category: this.settlementCategory,
        expenseType: 'PAYMENT',
        cost: amount,
        currencyCode: this.currencyCode,
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

      const [friendsResponse, expensesResponse] = await Promise.all([
        this.api.get(`/api/v1/friends/${this.auth.userId}`),
        this.api.get(`/api/v1/expense/user/${this.auth.userId}/friend/${them}`),
      ]);
      const allFriends = friendsResponse?.data ?? [];
      this.friend = allFriends.find((f) => String(f.id) === String(them)) ?? this.friend;
      this.expenses = expensesResponse?.data ?? [];
      this.showSettleForm = false;
    } catch (e) {
      this.settleError = e.message;
    } finally {
      this.isSettling = false;
    }
  }

  <template>
    <div class="page-back">
      <LinkTo @route="index">← Dashboard</LinkTo>
    </div>

    {{#if this.friend}}
      <div class="friend-detail-header">
        <div class="friend-detail-avatar">
          {{this.friend.firstName.[0]}}{{this.friend.lastName.[0]}}
        </div>
        <div class="friend-detail-info">
          <h2>{{this.friend.firstName}} {{this.friend.lastName}}</h2>
          <p class="friend-detail-email">{{this.friend.emailId}}</p>
          {{#if this.friend.balanceDto}}
            <BalanceBadge @balance={{this.friend.balanceDto}} />
          {{/if}}
        </div>
        {{#if this.balanceAmount}}
          <button type="button" class="btn-outline-teal" {{on "click" this.toggleSettleForm}}>
            {{if this.showSettleForm "Cancel" "Settle up"}}
          </button>
        {{/if}}
      </div>

      {{#if this.showSettleForm}}
        <form {{on "submit" this.recordSettlement}} class="form-card settle-form">
          {{#if this.settleError}}
            <div class="error-banner">{{this.settleError}}</div>
          {{/if}}
          <p class="form-hint">
            {{if this.owedToYou "They pay you" "You pay them"}} to settle up.
          </p>
          <div class="form-row">
            <div class="form-group">
              <label for="settle-amount">Amount ({{this.currencyCode}})</label>
              <input
                id="settle-amount"
                type="number"
                step="0.01"
                min="0.01"
                value={{this.settleAmount}}
                {{on "input" this.updateSettleAmount}}
              />
            </div>
          </div>
          <div class="form-actions">
            <button type="submit" class="btn-primary" disabled={{this.isSettling}}>
              {{if this.isSettling "Recording…" "Record Payment"}}
            </button>
          </div>
        </form>
      {{/if}}
    {{/if}}

    {{! ── Unified transaction timeline ── }}
    <h3 class="section-title">Transactions</h3>

    {{#if this.groupedExpenses.length}}
      {{#each this.groupedExpenses as |month|}}
        <div class="group-month-separator">{{month.label}}</div>
        {{#each month.items as |exp|}}
          <div class="group-exp-row">
            <div class="group-exp-date">
              <span class="group-exp-day">{{exp.dayNum}}</span>
              <span class="group-exp-month">{{exp.monthShort}}</span>
            </div>
            <div class="group-exp-icon">
              {{#if exp.groupName}}🏠{{else}}💰{{/if}}
            </div>
            <div class="group-exp-body">
              <div class="friend-exp-desc-row">
                <p class="group-exp-desc">{{exp.description}}</p>
                {{#if exp.groupName}}
                  <span class="friend-exp-group-badge">{{exp.groupName}}</span>
                {{/if}}
              </div>
              <p class="group-exp-payer">{{exp.formattedCost}}</p>
            </div>
            <div class="group-exp-share group-exp-share--{{exp.myShareType}}">
              {{exp.myShareLabel}}
            </div>
          </div>
        {{/each}}
      {{/each}}
    {{else}}
      <div class="empty-state">
        <p>No transactions yet.</p>
      </div>
    {{/if}}
  </template>
}

export default RouteTemplate(FriendsFriendTemplate);
