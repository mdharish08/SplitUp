import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';
import BalanceBadge from 'splitup-ui/components/balance-badge';

const AVATAR_COLORS = ['#f59e0b','#10b981','#8b5cf6','#f43f5e','#0ea5e9','#f97316','#6366f1'];
function friendAvatarColor(id) {
  const hash = Number(id ?? 0);
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

export class FriendsFriendTemplate extends Component {
  @service auth;
  @service api;
  @service router;
  @service toast;

  @tracked friend = this.args.model.friend;
  @tracked expenses = this.args.model.expenses;
  @tracked showSettleForm = false;
  @tracked settleAmount = '';
  @tracked isSettling = false;
  @tracked settleError = null;

  get avatarColor() {
    return friendAvatarColor(this.friend?.id);
  }

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

      const payerIsMe = String(exp.paidBy) === String(this.auth.userId);
      const enriched = {
        ...exp,
        myShareLabel,
        myShareType,
        dayNum: d.getDate(),
        monthShort: d.toLocaleDateString('en-US', { month: 'short' }).toUpperCase(),
        formattedCost: `${exp.currencyCode ?? ''} ${parseFloat(exp.cost ?? 0).toFixed(2)}`.trim(),
        payerName: payerIsMe ? 'you' : `${this.friend?.firstName ?? 'them'}`,
      };

      if (!cur || cur.key !== key) {
        cur = { key, label, items: [] };
        groups.push(cur);
      }
      cur.items.push(enriched);
    }

    return groups;
  }

  @action async unfriend() {
    if (!confirm(`Remove ${this.friend.firstName} as a friend?`)) return;
    try {
      await this.api.delete(`/api/v1/friends/${this.auth.userId}/${this.friend.id}`);
      this.toast.success(`${this.friend.firstName} removed from friends`);
      this.router.transitionTo('friends.index');
    } catch (e) {
      alert(e.message);
    }
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
    <div class="page-content page-content--narrow">
      <div class="page-back">
        <LinkTo @route="friends.index">← Friends</LinkTo>
      </div>

      {{#if this.friend}}
        <div class="friend-detail-header">
          <div class="friend-detail-avatar" style="background:{{this.avatarColor}}; color:#111110;">
            {{this.friend.firstName.[0]}}{{this.friend.lastName.[0]}}
          </div>
          <div class="friend-detail-info">
            <p class="page-eyebrow">Friend</p>
            <h1 class="friend-detail-name">{{this.friend.firstName}} {{this.friend.lastName}}</h1>
            <p class="friend-detail-email">{{this.friend.emailId}}</p>
          </div>
          {{#if this.friend.balanceDto}}
            <div class="friend-detail-balance">
              <p class="friend-detail-balance-label">Balance</p>
              <BalanceBadge @balance={{this.friend.balanceDto}} />
            </div>
          {{/if}}
          <div class="friend-detail-header-actions">
            {{#if this.balanceAmount}}
              <button type="button" class="btn-primary" {{on "click" this.toggleSettleForm}}>
                {{if this.showSettleForm "Cancel" "Settle up"}}
              </button>
            {{/if}}
            <button type="button" class="btn-danger" {{on "click" this.unfriend}}>
              Remove
            </button>
          </div>
        </div>

        {{#if this.showSettleForm}}
          <form {{on "submit" this.recordSettlement}} class="form-card">
            {{#if this.settleError}}
              <div class="error-banner">{{this.settleError}}</div>
            {{/if}}
            <p class="form-hint" style="margin-bottom:16px;">
              {{if this.owedToYou "They pay you" "You pay them"}} to settle up.
            </p>
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
            <div class="form-actions">
              <button type="submit" class="btn-primary" disabled={{this.isSettling}}>
                {{if this.isSettling "Recording…" "Record Payment"}}
              </button>
            </div>
          </form>
        {{/if}}
      {{/if}}

      {{! ── Transactions ── }}
      <p class="page-eyebrow" style="margin-top:32px; margin-bottom:12px;">Shared Expenses</p>

      {{#if this.groupedExpenses.length}}
        <div class="expense-table-header">
          <span class="expense-table-col-label--right expense-table-col-label">Date</span>
          <span class="expense-table-col-label">Category</span>
          <span class="expense-table-col-label">Description</span>
          <span class="expense-table-col-label--right expense-table-col-label">Amount</span>
        </div>
        {{#each this.groupedExpenses as |month|}}
          <div class="expense-month-group">
            <div class="expense-month-header">
              <span class="expense-month-label">{{month.label}}</span>
              <div class="expense-month-line"></div>
            </div>
            {{#each month.items as |exp|}}
              <div class="expense-row" style="cursor:default;">
                <span class="expense-row-date">{{exp.monthShort}} {{exp.dayNum}}</span>
                <span><span class="expense-cat-pill">{{exp.category.categoryName}}</span></span>
                <div class="expense-row-desc-wrap">
                  <div class="expense-row-desc-line">
                    <span class="expense-row-desc">{{exp.description}}</span>
                    {{#if exp.groupName}}
                      <span class="expense-cat-pill" style="background:#fffbeb; color:#d97706;">{{exp.groupName}}</span>
                    {{/if}}
                  </div>
                  <p class="expense-row-paid-by">paid by {{exp.payerName}}</p>
                </div>
                <div class="expense-row-amount-wrap">
                  <p class="expense-row-amount">{{exp.formattedCost}}</p>
                  <p class="expense-row-share expense-row-share--{{exp.myShareType}}">{{exp.myShareLabel}}</p>
                </div>
              </div>
            {{/each}}
          </div>
        {{/each}}
      {{else}}
        <div class="empty-state">
          <p>No transactions yet.</p>
        </div>
      {{/if}}
    </div>
  </template>
}

export default RouteTemplate(FriendsFriendTemplate);
