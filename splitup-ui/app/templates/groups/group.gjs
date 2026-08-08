import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { eq, fn } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';

const GROUP_TYPES = ['HOME', 'TRIP', 'COUPLE', 'OTHER'];

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

  // Edit group
  @tracked showEditModal = false;
  @tracked editName = '';
  @tracked editDescription = '';
  @tracked editGroupType = '';
  @tracked editCurrencyCode = '';
  @tracked isEditSaving = false;
  @tracked editError = null;

  groupTypes = GROUP_TYPES;
  currencies = ['USD', 'EUR', 'INR', 'GBP', 'JPY'];

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

  get groupInitials() {
    return (this.group?.name ?? '').slice(0, 2).toUpperCase();
  }

  get groupColor() {
    const name = this.group?.name ?? '';
    let hash = 0;
    for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
    const colors = ['#f59e0b','#10b981','#8b5cf6','#f43f5e','#0ea5e9','#f97316','#6366f1'];
    return colors[Math.abs(hash) % colors.length];
  }

  get myBalance() {
    const me = (this.group?.members ?? []).find((m) => m.id === this.currentUserId);
    return parseFloat(me?.balance?.amount ?? 0) || 0;
  }

  get myBalanceLabel() {
    const b = this.myBalance;
    if (Math.abs(b) < 0.01) return 'settled up';
    const currency = this.group?.currencyCode ?? '';
    return `${currency} ${Math.abs(b).toFixed(2)}`;
  }

  get myBalanceBadgeClass() {
    if (this.myBalance > 0) return 'balance-badge--positive';
    if (this.myBalance < 0) return 'balance-badge--negative';
    return 'balance-badge--neutral';
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

  // ── Edit group ──
  @action openEditModal() {
    this.editName = this.group.name ?? '';
    this.editDescription = this.group.description ?? '';
    this.editGroupType = this.group.groupType ?? 'OTHER';
    this.editCurrencyCode = this.group.currencyCode ?? 'USD';
    this.editError = null;
    this.showEditModal = true;
  }

  @action closeEditModal() {
    this.showEditModal = false;
    this.editError = null;
  }

  @action updateEditField(field, event) {
    this[field] = event.target.value;
  }

  @action async saveGroupEdit(event) {
    event.preventDefault();
    this.editError = null;
    this.isEditSaving = true;
    try {
      const body = {
        name: this.editName,
        description: this.editDescription,
        groupType: this.editGroupType,
        currencyCode: this.editCurrencyCode,
      };
      const response = await this.api.put(`/api/v1/group/${this.group.id}`, body);
      if (response?.code !== 0) throw new Error(response?.error ?? 'Failed to update group');
      // Refresh group data
      const groupsResponse = await this.api.get(`/api/v1/user/${this.auth.userId}/group`);
      const allGroups = groupsResponse?.data ?? [];
      this.group = allGroups.find((g) => String(g.id) === String(this.group.id)) ?? this.group;
      this.showEditModal = false;
    } catch (e) {
      this.editError = e.message;
    } finally {
      this.isEditSaving = false;
    }
  }

  // ── Delete group ──
  @action async deleteGroup() {
    if (!confirm(`Delete "${this.group.name}"? This cannot be undone.`)) return;
    try {
      await this.api.delete(`/api/v1/group/${this.group.id}`);
      this.router.transitionTo('groups.index');
    } catch (e) {
      alert(e.message);
    }
  }

  // ── Leave group ──
  @action async leaveGroup() {
    if (!confirm(`Leave "${this.group.name}"?`)) return;
    try {
      await this.api.delete(`/api/v1/group/${this.group.id}/member/${this.auth.userId}`);
      this.router.transitionTo('groups.index');
    } catch (e) {
      alert(e.message);
    }
  }

  // ── Remove member ──
  @action async removeMember(member) {
    if (!confirm(`Remove ${member.firstName} from this group?`)) return;
    try {
      await this.api.delete(`/api/v1/group/${this.group.id}/member/${member.id}`);
      const groupsResponse = await this.api.get(`/api/v1/user/${this.auth.userId}/group`);
      const allGroups = groupsResponse?.data ?? [];
      this.group = allGroups.find((g) => String(g.id) === String(this.group.id)) ?? this.group;
    } catch (e) {
      alert(e.message);
    }
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
    <div class="page-content page-content--wide">
      <div class="page-back">
        <LinkTo @route="groups.index">← Groups</LinkTo>
      </div>

    {{#if this.group}}
      {{! ── Group header ── }}
      <div class="group-detail-header">
        <div class="group-detail-icon" style="background:{{this.groupColor}}; color:#111110;">
          {{this.groupInitials}}
        </div>
        <div class="group-detail-info">
          <p class="page-eyebrow">Group</p>
          <h1 class="group-detail-name">{{this.group.name}}</h1>
          <p class="group-detail-meta">
            {{this.group.members.length}} members · {{this.group.currencyCode}}
          </p>
        </div>
        <div class="group-detail-balance">
          <p class="group-detail-balance-label">Your balance</p>
          <span class="balance-badge {{this.myBalanceBadgeClass}}">{{this.myBalanceLabel}}</span>
        </div>
        <div class="group-detail-actions">
          <button type="button" class="btn-primary" {{on "click" this.addExpense}}>+ Add Expense</button>
          <button type="button" class="btn-secondary" {{on "click" this.openEditModal}}>Edit</button>
          <button type="button" class="btn-secondary" {{on "click" this.leaveGroup}}>Leave</button>
          <button type="button" class="btn-danger" {{on "click" this.deleteGroup}}>Delete</button>
        </div>
      </div>

      {{! ── Two-column body ── }}
      <div class="group-detail-layout">

        {{! ── Left: expense feed ── }}
        <div>
          <p class="page-eyebrow" style="margin-bottom:12px;">Expenses</p>
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
                      <span class="expense-row-desc">{{exp.description}}</span>
                      <p class="expense-row-paid-by">{{exp.payerName}} paid {{exp.formattedCost}}</p>
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
              <p>No expenses yet.</p>
              <button type="button" class="btn-primary" {{on "click" this.addExpense}}>Add first expense</button>
            </div>
          {{/if}}
        </div>

        {{! ── Right: member balances panel ── }}
        <div class="group-member-panel">
          <p class="group-member-panel-title">Member Balances</p>

          {{#if this.settleError}}
            <div class="error-banner">{{this.settleError}}</div>
          {{/if}}

          {{#each this.membersWithMeta as |member|}}
            <div class="group-member-card">
              {{! Top row: avatar + name + balance }}
              <div class="group-member-row">
                <div class="group-member-avatar" style="background:{{member.avatarColor}}; color:#111110;">
                  {{member.initials}}
                </div>
                <div class="group-member-info">
                  <p class="group-member-name">
                    {{member.firstName}} {{member.lastName}}
                    {{#if member.isMe}}<span class="group-member-you">(you)</span>{{/if}}
                  </p>
                  {{#if member.hasBalance}}
                    {{#if member.owedToMe}}
                      <p class="group-member-balance group-member-balance--negative">owes {{member.balanceCurrency}} {{member.absBalance}}</p>
                    {{else}}
                      <p class="group-member-balance group-member-balance--positive">gets back {{member.balanceCurrency}} {{member.absBalance}}</p>
                    {{/if}}
                  {{else}}
                    <p class="group-member-balance group-member-balance--neutral">settled up</p>
                  {{/if}}
                </div>
              </div>

              {{! Action row: indented below name }}
              {{#unless member.isMe}}
                <div class="balance-member-actions">
                  {{#if member.hasBalance}}
                    <button type="button" class="settle-btn-small" {{on "click" (fn this.toggleSettle member)}}>
                      {{if (eq this.settlingMemberId member.id) "Cancel" "Settle"}}
                    </button>
                  {{/if}}
                  <button type="button" class="btn-danger-sm" {{on "click" (fn this.removeMember member)}}>Remove</button>
                </div>
              {{/unless}}

              {{! Settle form }}
              {{#if (eq this.settlingMemberId member.id)}}
                <form class="settle-form" {{on "submit" (fn this.recordSettlement member)}}>
                  <input
                    type="number" step="0.01" min="0.01"
                    value={{this.settleAmount}}
                    {{on "input" this.updateSettleAmount}}
                    class="settle-amount-input"
                    placeholder="Amount"
                  />
                  <button type="submit" class="btn-primary settle-ok-btn" disabled={{this.isSettling}}>
                    {{if this.isSettling "…" "Confirm"}}
                  </button>
                </form>
              {{/if}}
            </div>
          {{/each}}
        </div>
      </div>
    {{/if}}

    {{! ── Edit Group Modal ── }}
    {{#if this.showEditModal}}
      <div class="modal-overlay">
        <div class="modal-card">
          <div class="modal-header">
            <h3>Edit Group</h3>
            <button type="button" class="modal-close" {{on "click" this.closeEditModal}}>×</button>
          </div>
          {{#if this.editError}}
            <div class="error-banner">{{this.editError}}</div>
          {{/if}}
          <form {{on "submit" this.saveGroupEdit}} class="form-card">
            <div class="form-group">
              <label for="edit-group-name">Group Name</label>
              <input
                id="edit-group-name"
                type="text"
                value={{this.editName}}
                {{on "input" (fn this.updateEditField "editName")}}
                required
              />
            </div>
            <div class="form-group">
              <label for="edit-group-desc">Description</label>
              <input
                id="edit-group-desc"
                type="text"
                value={{this.editDescription}}
                {{on "input" (fn this.updateEditField "editDescription")}}
              />
            </div>
            <div class="form-row">
              <div class="form-group">
                <label for="edit-group-type">Type</label>
                <select id="edit-group-type" {{on "change" (fn this.updateEditField "editGroupType")}}>
                  {{#each this.groupTypes as |type|}}
                    <option value={{type}} selected={{eq type this.editGroupType}}>{{type}}</option>
                  {{/each}}
                </select>
              </div>
              <div class="form-group">
                <label for="edit-group-currency">Currency</label>
                <select id="edit-group-currency" {{on "change" (fn this.updateEditField "editCurrencyCode")}}>
                  {{#each this.currencies as |code|}}
                    <option value={{code}} selected={{eq code this.editCurrencyCode}}>{{code}}</option>
                  {{/each}}
                </select>
              </div>
            </div>
            <div class="form-actions">
              <button type="submit" class="btn-primary" disabled={{this.isEditSaving}}>
                {{if this.isEditSaving "Saving…" "Save Changes"}}
              </button>
              <button type="button" class="btn-secondary" {{on "click" this.closeEditModal}}>Cancel</button>
            </div>
          </form>
        </div>
      </div>
    {{/if}}
    </div>{{! end .page-content }}
  </template>
}

export default RouteTemplate(GroupsGroupTemplate);
