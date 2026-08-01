import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn, eq } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';

function idEq(a, b) {
  return String(a) === String(b);
}

export class ExpensesNewTemplate extends Component {
  @service api;
  @service auth;
  @service router;

  @tracked description = '';
  @tracked cost = '';
  @tracked currencyCode = 'USD';
  @tracked expenseType = 'EXPENSE';
  @tracked selectedCategoryId = '';
  @tracked groupId = '';
  @tracked payerId = this.auth.userId;
  @tracked splitType = 'EQUAL';
  @tracked participants = [this.selfParticipant];
  @tracked errorMessage = null;
  @tracked isLoading = false;

  currencies = ['USD', 'EUR', 'INR', 'GBP', 'JPY'];
  expenseTypes = ['EXPENSE', 'PAYMENT'];

  constructor(owner, args) {
    super(owner, args);
    // Pre-select group and members when navigated from a group page
    const preId = String(args.model.preselectedGroupId ?? '');
    if (preId) {
      const group = args.model.groups.find((g) => String(g.id) === preId);
      if (group) {
        this.groupId = preId;
        this.currencyCode = group.currencyCode ?? 'USD';
        const selfId = Number(this.auth.userId);
        this.participants = (group.members ?? []).map((m) => ({
          userId: m.id,
          firstName: m.id === selfId ? 'You' : m.firstName,
          lastName: m.id === selfId ? '' : m.lastName,
          owedShare: '',
        }));
      }
    }
  }

  get selfParticipant() {
    return { userId: Number(this.auth.userId), firstName: 'You', lastName: '', owedShare: '' };
  }

  get selectedGroup() {
    if (!this.groupId) return null;
    return this.args.model.groups.find((g) => String(g.id) === String(this.groupId)) ?? null;
  }

  get totalCost() {
    return parseFloat(this.cost) || 0;
  }

  get totalEntered() {
    return this.participants.reduce((sum, p) => sum + (parseFloat(p.owedShare) || 0), 0);
  }

  get remainingAmount() {
    return (this.totalCost - this.totalEntered).toFixed(2);
  }

  get participantNames() {
    return this.participants.map((p) => `${p.firstName} ${p.lastName}`.trim()).join(', ');
  }

  get registeredFriends() {
    return (this.args.model.friends ?? []).filter((f) => f.id != null);
  }

  get pendingFriendCount() {
    return (this.args.model.friends ?? []).filter((f) => f.id == null).length;
  }

  @action goBack(event) {
    event?.preventDefault();
    if (this.args.model.preselectedGroupId) {
      this.router.transitionTo('groups.group', this.args.model.preselectedGroupId);
    } else {
      this.router.transitionTo('index');
    }
  }

  @action updateField(field, event) {
    this[field] = event.target.value;
  }

  @action selectGroup(event) {
    const groupId = event.target.value;
    this.groupId = groupId;
    if (groupId) {
      const group = this.args.model.groups.find((g) => String(g.id) === String(groupId));
      const selfId = Number(this.auth.userId);
      this.participants = (group?.members ?? []).map((m) => ({
        userId: m.id,
        firstName: m.id === selfId ? 'You' : m.firstName,
        lastName: m.id === selfId ? '' : m.lastName,
        owedShare: '',
      }));
      this.currencyCode = group?.currencyCode ?? this.currencyCode;
    } else {
      this.participants = [this.selfParticipant];
    }
  }

  @action setSplitType(type) {
    this.splitType = type;
  }

  @action toggleParticipant(friend) {
    const exists = this.participants.find((p) => p.userId === friend.id);
    if (exists) {
      this.participants = this.participants.filter((p) => p.userId !== friend.id);
    } else {
      this.participants = [
        ...this.participants,
        { userId: friend.id, firstName: friend.firstName, lastName: friend.lastName, owedShare: '' },
      ];
    }
  }

  isSelected = (friendId) => {
    return !!this.participants.find((p) => p.userId === friendId);
  };

  @action updateOwedShare(userId, event) {
    const value = event.target.value;
    this.participants = this.participants.map((p) =>
      p.userId === userId ? { ...p, owedShare: value } : p,
    );
  }

  get splitUsers() {
    const count = this.participants.length || 1;
    return this.participants.map((p) => {
      const owedShare =
        this.splitType === 'EQUAL' ? this.totalCost / count : parseFloat(p.owedShare) || 0;
      const paidShare = String(p.userId) === String(this.payerId) ? this.totalCost : 0;
      return { userId: p.userId, paidShare, owedShare, netBalance: paidShare - owedShare };
    });
  }

  @action async handleSubmit(event) {
    event.preventDefault();
    this.errorMessage = null;

    const category = this.args.model.categories.find(
      (c) => String(c.categoryId) === String(this.selectedCategoryId),
    );
    if (!category) {
      this.errorMessage = 'Select a category';
      return;
    }
    if (!this.payerId) {
      this.errorMessage = 'Select who paid';
      return;
    }
    if (this.participants.length === 0) {
      this.errorMessage = 'Add at least one participant';
      return;
    }
    if (this.splitType === 'EXACT' && Math.abs(this.totalCost - this.totalEntered) > 0.01) {
      this.errorMessage = `Shares must add up to ${this.totalCost.toFixed(2)} (currently ${this.totalEntered.toFixed(2)})`;
      return;
    }

    this.isLoading = true;
    try {
      const body = {
        category,
        expenseType: this.expenseType,
        cost: this.totalCost,
        currencyCode: this.currencyCode,
        groupId: this.groupId ? Number(this.groupId) : null,
        description: this.description,
        paidBy: Number(this.payerId),
        users: this.splitUsers,
      };
      const response = await this.api.post('/api/v1/expense', body);
      if (response?.code !== 0) throw new Error(response?.error ?? 'Failed to add expense');

      // Navigate back to the originating group, or the dashboard
      if (this.groupId) {
        this.router.transitionTo('groups.group', this.groupId);
      } else {
        this.router.transitionTo('index');
      }
    } catch (e) {
      this.errorMessage = e.message;
    } finally {
      this.isLoading = false;
    }
  }

  <template>
    <div class="page-back">
      <a href="#" {{on "click" this.goBack}}>
        ← {{if this.args.model.preselectedGroupId this.selectedGroup.name "Dashboard"}}
      </a>
    </div>

    <h2>Add Expense</h2>

    {{! Group context banner — shown when launched from a group page }}
    {{#if this.selectedGroup}}
      <div class="expense-group-context">
        <span class="expense-group-context-icon">{{this.selectedGroup.name.[0]}}</span>
        <span>
          With you and: <strong>All of {{this.selectedGroup.name}}</strong>
          · {{this.selectedGroup.members.length}} people
        </span>
      </div>
    {{/if}}

    {{#if this.errorMessage}}
      <div class="error-banner">{{this.errorMessage}}</div>
    {{/if}}

    <form {{on "submit" this.handleSubmit}} class="form-card">
      <div class="form-group">
        <label for="expense-desc">Description</label>
        <input
          id="expense-desc"
          type="text"
          value={{this.description}}
          {{on "input" (fn this.updateField "description")}}
          placeholder="e.g. Dinner at Olive Garden"
          required
        />
      </div>

      <div class="form-row">
        <div class="form-group">
          <label for="cost">Amount</label>
          <input
            id="cost"
            type="number"
            step="0.01"
            min="0"
            value={{this.cost}}
            {{on "input" (fn this.updateField "cost")}}
            required
          />
        </div>
        <div class="form-group">
          <label for="expense-currency">Currency</label>
          <select id="expense-currency" {{on "change" (fn this.updateField "currencyCode")}}>
            {{#each this.currencies as |code|}}
              <option value={{code}} selected={{eq code this.currencyCode}}>{{code}}</option>
            {{/each}}
          </select>
        </div>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label for="category">Category</label>
          <select id="category" {{on "change" (fn this.updateField "selectedCategoryId")}}>
            <option value="">-- Select category --</option>
            {{#each @model.categories as |cat|}}
              <option
                value={{cat.categoryId}}
                selected={{idEq cat.categoryId this.selectedCategoryId}}
              >{{cat.categoryName}}</option>
            {{/each}}
          </select>
        </div>
        <div class="form-group">
          <label for="expense-type">Type</label>
          <select id="expense-type" {{on "change" (fn this.updateField "expenseType")}}>
            {{#each this.expenseTypes as |type|}}
              <option value={{type}} selected={{eq type this.expenseType}}>{{type}}</option>
            {{/each}}
          </select>
        </div>
      </div>

      {{! Group selector — hidden when already in a group context }}
      {{#unless @model.preselectedGroupId}}
        <div class="form-group">
          <label for="group-select">Group</label>
          <select id="group-select" {{on "change" this.selectGroup}}>
            <option value="">-- Personal expense --</option>
            {{#each @model.groups as |group|}}
              <option value={{group.id}} selected={{idEq group.id this.groupId}}>{{group.name}}</option>
            {{/each}}
          </select>
        </div>
      {{/unless}}

      {{! Participants — auto-populated from group or manually selected }}
      {{#if this.groupId}}
        <div class="form-group">
          <label>Split with (group members)</label>
          <div class="participant-list">
            {{#each this.participants key="userId" as |p|}}
              <div class="participant-member-row">
                <span class="participant-member-name">{{p.firstName}} {{p.lastName}}</span>
              </div>
            {{/each}}
          </div>
        </div>
      {{else}}
        <div class="form-group">
          <label>Select Participants</label>
          <p class="form-hint">Check everyone splitting this expense</p>
          <div class="participant-list">
            {{#each this.registeredFriends key="id" as |friend|}}
              <label class="participant-label">
                <input
                  type="checkbox"
                  checked={{this.isSelected friend.id}}
                  {{on "change" (fn this.toggleParticipant friend)}}
                />
                <span>{{friend.firstName}} {{friend.lastName}}</span>
                <span class="participant-email">{{friend.emailId}}</span>
              </label>
            {{/each}}
          </div>
          {{#if this.pendingFriendCount}}
            <p class="form-hint form-hint--muted">
              {{this.pendingFriendCount}}
              {{if (eq this.pendingFriendCount 1) "invited friend" "invited friends"}}
              can't be added yet — they'll appear here once they join SplitUp.
            </p>
          {{/if}}
        </div>
      {{/if}}

      <div class="form-group">
        <label for="payer">Who paid?</label>
        <select id="payer" {{on "change" (fn this.updateField "payerId")}}>
          {{#each this.participants key="userId" as |p|}}
            <option value={{p.userId}} selected={{idEq p.userId this.payerId}}>
              {{p.firstName}} {{p.lastName}}
            </option>
          {{/each}}
        </select>
      </div>

      <div class="form-group">
        <label>Split</label>
        <div class="split-toggle">
          <button
            type="button"
            class={{if (eq this.splitType "EQUAL") "btn-primary" "btn-secondary"}}
            {{on "click" (fn this.setSplitType "EQUAL")}}
          >Equally</button>
          <button
            type="button"
            class={{if (eq this.splitType "EXACT") "btn-primary" "btn-secondary"}}
            {{on "click" (fn this.setSplitType "EXACT")}}
          >Exact amounts</button>
        </div>

        {{#if (eq this.splitType "EXACT")}}
          <div class="split-inputs">
            {{#each this.participants key="userId" as |p|}}
              <div class="split-row">
                <span class="split-name">{{p.firstName}} {{p.lastName}}</span>
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="amount"
                  class="share-input"
                  value={{p.owedShare}}
                  {{on "input" (fn this.updateOwedShare p.userId)}}
                />
              </div>
            {{/each}}
          </div>
          <p class="form-hint">Remaining to assign: {{this.remainingAmount}}</p>
        {{else}}
          <p class="form-hint">
            Split equally among {{this.participants.length}}
            {{if (eq this.participants.length 1) "person" "people"}}
          </p>
        {{/if}}
      </div>

      <div class="form-actions">
        <button type="submit" class="btn-primary" disabled={{this.isLoading}}>
          {{if this.isLoading "Adding…" "Add Expense"}}
        </button>
        <button type="button" class="btn-secondary" {{on "click" this.goBack}}>Cancel</button>
      </div>
    </form>
  </template>
}

export default RouteTemplate(ExpensesNewTemplate);
