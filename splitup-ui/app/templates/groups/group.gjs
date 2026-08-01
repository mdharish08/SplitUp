import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { eq, fn } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';

const AVATAR_COLORS = [
  '#e9856d', '#5cbca6', '#7b68ee', '#ff8c00',
  '#6495ed', '#20b2aa', '#dc143c', '#c084fc',
];

export class GroupsGroupTemplate extends Component {
  @service auth;
  @service api;
  @service router;

  @tracked group = this.args.model.group;
  @tracked expenses = this.args.model.expenses;
  @tracked settlingMemberId = null;
  @tracked settleAmount = '';
  @tracked isSettling = false;
  @tracked settleError = null;

  get settlementCategory() {
    const categories = this.args.model.categories ?? [];
    return categories.find((c) => c.categoryName === 'Other') ?? categories[0];
  }

  get currentUserId() {
    return Number(this.auth.userId);
  }

  get groupIcon() {
    return (this.group?.name?.[0] ?? '?').toUpperCase();
  }

  get membersWithMeta() {
    return (this.group?.members ?? []).map((m, i) => {
      const amount = parseFloat(m.balance?.amount ?? 0) || 0;
      const initials =
        `${(m.firstName?.[0] ?? '').toUpperCase()}${(m.lastName?.[0] ?? '').toUpperCase()}` || '?';
      return {
        ...m,
        avatarColor: AVATAR_COLORS[i % AVATAR_COLORS.length],
        initials,
        balanceAmount: amount,
        absBalance: Math.abs(amount).toFixed(2),
        balanceCurrency: m.balance?.currency_code ?? this.group?.currencyCode ?? '',
        hasBalance: Math.abs(amount) >= 0.01,
        owedToMe: amount > 0,
        isMe: m.id === this.currentUserId,
      };
    });
  }

  get groupedExpenses() {
    const userId = String(this.auth.userId);
    const memberMap = {};
    for (const m of this.group?.members ?? []) {
      memberMap[String(m.id)] = m.firstName ?? `User ${m.id}`;
    }

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
        const cur2 = exp.currencyCode ?? '';
        if (paid > 0) {
          myShareLabel = `you paid ${cur2} ${parseFloat(exp.cost ?? 0).toFixed(2)}`.trim();
          myShareType = 'positive';
        } else if (owed > 0) {
          myShareLabel = `you owe ${cur2} ${owed.toFixed(2)}`.trim();
          myShareType = 'negative';
        }
      }

      const payerName = memberMap[String(exp.paidBy)] ?? `User ${exp.paidBy}`;
      const enriched = {
        ...exp,
        myShareLabel,
        myShareType,
        payerName,
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

  @action addExpense() {
    this.router.transitionTo('expenses.new', {
      queryParams: { groupId: this.group.id },
    });
  }

  @action settleFirst() {
    const first = this.membersWithMeta.find((m) => !m.isMe && m.hasBalance);
    if (first) this.toggleSettle(first);
  }

  @action toggleSettle(member) {
    if (this.settlingMemberId === member.id) {
      this.settlingMemberId = null;
      this.settleError = null;
      return;
    }
    this.settlingMemberId = member.id;
    this.settleAmount = Math.abs(member.balanceAmount).toFixed(2);
    this.settleError = null;
  }

  @action updateSettleAmount(event) {
    this.settleAmount = event.target.value;
  }

  @action async recordSettlement(member, event) {
    event.preventDefault();
    this.settleError = null;

    const amount = parseFloat(this.settleAmount);
    if (!amount || amount <= 0) {
      this.settleError = 'Enter an amount greater than zero';
      return;
    }
    if (!this.settlementCategory) {
      this.settleError = 'No category available';
      return;
    }

    const you = Number(this.auth.userId);
    const them = member.id;
    const payerId = member.owedToMe ? them : you;
    const creditorId = member.owedToMe ? you : them;

    this.isSettling = true;
    try {
      const body = {
        category: this.settlementCategory,
        expenseType: 'PAYMENT',
        cost: amount,
        currencyCode: member.balanceCurrency || this.group.currencyCode,
        groupId: this.group.id,
        description: 'Settle up',
        paidBy: payerId,
        users: [
          { userId: payerId, paidShare: amount, owedShare: 0, netBalance: amount },
          { userId: creditorId, paidShare: 0, owedShare: amount, netBalance: -amount },
        ],
      };
      const response = await this.api.post('/api/v1/expense', body);
      if (response?.code !== 0) throw new Error(response?.error ?? 'Failed to record payment');

      const [groupsResponse, expensesResponse] = await Promise.all([
        this.api.get(`/api/v1/user/${this.auth.userId}/group`),
        this.api.get(`/api/v1/expense/group/${this.group.id}`),
      ]);
      const allGroups = groupsResponse?.data ?? [];
      this.group =
        allGroups.find((g) => String(g.id) === String(this.group.id)) ?? this.group;
      this.expenses = expensesResponse?.data ?? [];
      this.settlingMemberId = null;
    } catch (e) {
      this.settleError = e.message;
    } finally {
      this.isSettling = false;
    }
  }

  <template>
    <div class="page-back">
      <LinkTo @route="groups">← Groups</LinkTo>
    </div>

    {{#if this.group}}
      {{! ── Group header ── }}
      <div class="group-detail-header">
        <div class="group-detail-icon">{{this.groupIcon}}</div>
        <div class="group-detail-info">
          <h2>{{this.group.name}}</h2>
          <p class="group-detail-sub">
            {{this.group.members.length}} people · {{this.group.groupType}} · {{this.group.currencyCode}}
          </p>
          {{#if this.group.description}}
            <p class="group-description">{{this.group.description}}</p>
          {{/if}}
        </div>
        <div class="group-detail-actions">
          <button type="button" class="btn-orange" {{on "click" this.addExpense}}>+ Add an expense</button>
          <button type="button" class="btn-outline-teal" {{on "click" this.settleFirst}}>
            Settle up
          </button>
        </div>
      </div>

      {{! ── Two-column body ── }}
      <div class="group-page-layout">

        {{! ── Left: expense feed ── }}
        <div class="group-expenses-col">
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
                    {{#if (eq exp.expenseType "PAYMENT")}}💸{{else}}💰{{/if}}
                  </div>
                  <div class="group-exp-body">
                    <p class="group-exp-desc">{{exp.description}}</p>
                    <p class="group-exp-payer">{{exp.payerName}} paid {{exp.formattedCost}}</p>
                  </div>
                  <div class="group-exp-share group-exp-share--{{exp.myShareType}}">
                    {{exp.myShareLabel}}
                  </div>
                </div>
              {{/each}}
            {{/each}}
          {{else}}
            <div class="empty-state">
              <p>No expenses yet.</p>
              <button type="button" class="btn-primary" {{on "click" this.addExpense}}>Add first expense</button>
            </div>
          {{/if}}
        </div>

        {{! ── Right: GROUP BALANCES panel ── }}
        <div class="group-balances-col">
          <div class="balances-panel">
            <h4 class="balances-panel-title">GROUP BALANCES</h4>

            {{#if this.settleError}}
              <div class="error-banner settle-error">{{this.settleError}}</div>
            {{/if}}

            {{#each this.membersWithMeta as |member|}}
              <div class="balance-member-row">
                <div
                  class="balance-member-avatar"
                  style="background: {{member.avatarColor}}"
                >
                  {{member.initials}}
                </div>
                <div class="balance-member-info">
                  <p class="balance-member-name">
                    {{member.firstName}} {{member.lastName}}
                    {{#if member.isMe}}<span class="chip-you-label">(you)</span>{{/if}}
                  </p>
                  {{#if member.hasBalance}}
                    {{#if member.owedToMe}}
                      <p class="balance-member-status balance-member-status--negative">
                        owes {{member.balanceCurrency}} {{member.absBalance}}
                      </p>
                    {{else}}
                      <p class="balance-member-status balance-member-status--positive">
                        gets back {{member.balanceCurrency}} {{member.absBalance}}
                      </p>
                    {{/if}}
                  {{else}}
                    <p class="balance-member-status balance-member-status--neutral">settled up</p>
                  {{/if}}
                </div>
                {{#unless member.isMe}}
                  {{#if member.hasBalance}}
                    <button
                      type="button"
                      class="settle-btn-small"
                      {{on "click" (fn this.toggleSettle member)}}
                    >
                      {{if (eq this.settlingMemberId member.id) "Cancel" "Settle"}}
                    </button>
                  {{/if}}
                {{/unless}}
              </div>

              {{#if (eq this.settlingMemberId member.id)}}
                <form
                  {{on "submit" (fn this.recordSettlement member)}}
                  class="settle-inline-form"
                >
                  <input
                    type="number"
                    step="0.01"
                    min="0.01"
                    value={{this.settleAmount}}
                    {{on "input" this.updateSettleAmount}}
                    class="settle-inline-input"
                    placeholder="Amount"
                  />
                  <button
                    type="submit"
                    class="btn-primary btn-small"
                    disabled={{this.isSettling}}
                  >
                    {{if this.isSettling "…" "Confirm"}}
                  </button>
                </form>
              {{/if}}
            {{/each}}
          </div>
        </div>
      </div>
    {{/if}}
  </template>
}

export default RouteTemplate(GroupsGroupTemplate);
