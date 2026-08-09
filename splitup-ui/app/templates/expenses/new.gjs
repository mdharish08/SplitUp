import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn, eq } from '@ember/helper';
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

  get registeredFriends() {
    return (this.args.model.friends ?? []).filter((f) => f.id != null);
  }

  get pendingFriendCount() {
    return (this.args.model.friends ?? []).filter((f) => f.id == null).length;
  }

  get breadcrumbLabel() {
    return this.selectedGroup?.name ?? 'All Expenses';
  }

  // ── Step gate: show split panel once amount is entered and members are ready ──
  get showSplitPanel() {
    return this.totalCost > 0 && this.participants.length >= 1;
  }

  get equalSplitAmount() {
    const count = this.participants.length || 1;
    return (this.totalCost / count).toFixed(2);
  }

  get totalShares() {
    return this.participants.reduce((sum, p) => sum + (parseFloat(p.owedShare) || 0), 0);
  }

  get totalPercentage() {
    return this.participants.reduce((sum, p) => sum + (parseFloat(p.owedShare) || 0), 0);
  }

  get totalPercentageFormatted() {
    return this.totalPercentage.toFixed(1);
  }

  get splitIsValid() {
    if (!this.showSplitPanel) return false;
    if (this.splitType === 'EXACT') {
      return Math.abs(this.totalCost - this.totalEntered) <= 0.01;
    }
    if (this.splitType === 'PERCENTAGE') {
      return Math.abs(this.totalPercentage - 100) <= 0.01;
    }
    // EQUAL and SHARES are always valid once amount is set
    return true;
  }

  // Add Expense button only shows when split balances out
  get canSubmit() {
    return this.splitIsValid && this.totalCost > 0;
  }

  get splitUsers() {
    const count = this.participants.length || 1;
    const total = this.totalCost;

    return this.participants.map((p) => {
      let owedShare;
      const entered = parseFloat(p.owedShare) || 0;

      switch (this.splitType) {
        case 'EQUAL':
          owedShare = total / count;
          break;
        case 'EXACT':
          owedShare = entered;
          break;
        case 'PERCENTAGE':
          owedShare = (entered / 100) * total;
          break;
        case 'SHARES': {
          const shares = this.totalShares || 1;
          owedShare = (entered / shares) * total;
          break;
        }
        default:
          owedShare = total / count;
      }

      const paidShare = String(p.userId) === String(this.payerId) ? total : 0;
      return { userId: p.userId, paidShare, owedShare, netBalance: paidShare - owedShare };
    });
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
    if (!this.splitIsValid) {
      if (this.splitType === 'EXACT') {
        this.errorMessage = `Amounts must add up to ${this.totalCost.toFixed(2)} (currently ${this.totalEntered.toFixed(2)})`;
      } else if (this.splitType === 'PERCENTAGE') {
        this.errorMessage = `Percentages must add up to 100% (currently ${this.totalPercentage.toFixed(1)}%)`;
      }
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
    <form
      class="ne-page {{if this.showSplitPanel 'ne-page--split-open' ''}}"
      {{on "submit" this.handleSubmit}}
    >

      {{! ── LEFT: form fields ── }}
      <div class="ne-form-area">
        <div class="page-back">
          <a href="#" {{on "click" this.goBack}}>
            ← {{this.breadcrumbLabel}}
          </a>
        </div>

        <div class="ne-title-block">
          <p class="page-eyebrow">Record</p>
          <h1 class="page-title">Add Expense</h1>
        </div>

        {{#if @model.preselectedGroupId}}
          <div class="expense-group-context">
            <span>Group: {{this.selectedGroup.name}}</span>
          </div>
        {{/if}}

        {{#if this.errorMessage}}
          <div class="error-banner">{{this.errorMessage}}</div>
        {{/if}}

        {{! ── STEP 1: Amount ── }}
        <div class="ne-step-label">
          <span class="ne-step-number">1</span>
          How much?
        </div>
        <div class="ne-amount-hero">
          <select class="ne-hero-currency" {{on "change" (fn this.updateField "currencyCode")}}>
            {{#each this.currencies as |code|}}
              <option value={{code}} selected={{eq code this.currencyCode}}>{{code}}</option>
            {{/each}}
          </select>
          <input
            id="cost" type="number" class="ne-hero-input"
            step="0.01" min="0" placeholder="0.00"
            value={{this.cost}}
            {{on "input" (fn this.updateField "cost")}}
            autofocus required
          />
        </div>

        {{! ── STEP 2: Details + Members ── }}
        <div class="ne-step-label">
          <span class="ne-step-number">2</span>
          Details &amp; who's splitting?
        </div>

        <div class="ne-fields-grid">
          <div class="form-group">
            <label for="expense-desc">Description</label>
            <input
              id="expense-desc" type="text"
              value={{this.description}}
              {{on "input" (fn this.updateField "description")}}
              placeholder="e.g. Dinner at Noma"
              required
            />
          </div>

          <div class="form-group">
            <label for="payer">Paid By</label>
            <select id="payer" {{on "change" (fn this.updateField "payerId")}}>
              {{#each this.participants key="userId" as |p|}}
                <option value={{p.userId}} selected={{idEq p.userId this.payerId}}>
                  {{p.firstName}} {{p.lastName}}
                </option>
              {{/each}}
            </select>
          </div>

          <div class="form-group">
            <label for="category">Category</label>
            <select id="category" {{on "change" (fn this.updateField "selectedCategoryId")}}>
              <option value="">-- Select category --</option>
              {{#each @model.categories as |cat|}}
                <option value={{cat.categoryId}} selected={{idEq cat.categoryId this.selectedCategoryId}}>
                  {{cat.categoryName}}
                </option>
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

          {{! Group picker — only for personal (non-group) expenses }}
          {{#unless @model.preselectedGroupId}}
            <div class="form-group">
              <label for="group-select">Group <span class="ne-optional">(Optional)</span></label>
              <select id="group-select" {{on "change" this.selectGroup}}>
                <option value="">— Personal expense —</option>
                {{#each @model.groups as |group|}}
                  <option value={{group.id}} selected={{idEq group.id this.groupId}}>{{group.name}}</option>
                {{/each}}
              </select>
            </div>
          {{/unless}}
        </div>

        {{! Friend picker — only for personal (non-group) expenses }}
        {{#unless this.groupId}}
          <div class="form-group">
            <label>Split With</label>
            <p class="form-hint">Select everyone sharing this expense</p>
            <div class="participant-list">
              {{#each this.registeredFriends key="id" as |friend|}}
                <label class="participant-label">
                  <input type="checkbox"
                    checked={{this.isSelected friend.id}}
                    {{on "change" (fn this.toggleParticipant friend)}} />
                  <span>{{friend.firstName}} {{friend.lastName}}</span>
                  <span class="participant-email">{{friend.emailId}}</span>
                </label>
              {{/each}}
            </div>
            {{#if this.pendingFriendCount}}
              <p class="form-hint form-hint--muted">
                {{this.pendingFriendCount}}
                {{if (eq this.pendingFriendCount 1) "invited friend" "invited friends"}}
                can't be added until they join SplitUp.
              </p>
            {{/if}}
          </div>
        {{/unless}}

        {{#if this.groupId}}
          <div class="form-group">
            <label>Participants</label>
            <div class="participant-list">
              {{#each this.participants key="userId" as |p|}}
                <div class="participant-member-row">
                  <span class="participant-member-name">{{p.firstName}} {{p.lastName}}</span>
                </div>
              {{/each}}
            </div>
          </div>
        {{/if}}

        {{! ── Prompt to enter amount if not yet ── }}
        {{#unless this.showSplitPanel}}
          <div class="ne-split-pending-hint">
            Enter an amount above to configure how it's split →
          </div>
        {{/unless}}

        {{! ── Add Expense button: always visible, disabled until split is valid ── }}
        <div class="ne-form-footer">
          <button
            type="submit"
            class="btn-primary ne-submit"
            disabled={{if this.isLoading true (if this.canSubmit false true)}}
          >
            {{if this.isLoading "Adding…" "Add Expense"}}
          </button>
          {{#unless this.canSubmit}}
            {{#if this.showSplitPanel}}
              <p class="ne-submit-hint">
                {{#if (eq this.splitType "EXACT")}}
                  {{this.cost}} total — {{this.remainingAmount}} still unassigned
                {{else if (eq this.splitType "PERCENTAGE")}}
                  {{this.totalPercentageFormatted}}% of 100% assigned
                {{else}}
                  Enter an amount to continue
                {{/if}}
              </p>
            {{else}}
              <p class="ne-submit-hint">Enter an amount to continue</p>
            {{/if}}
          {{/unless}}
        </div>

      </div>{{! end ne-form-area }}

      {{! ── RIGHT: live split panel — only visible once amount + members are set ── }}
      {{#if this.showSplitPanel}}
        <div class="ne-split-panel">

          {{! Total summary card }}
          <div class="ne-split-total">
            <p class="ne-split-total-label">Splitting</p>
            <p class="ne-split-total-amount">{{this.currencyCode}} {{this.cost}}</p>
            <p class="ne-split-total-sub">
              among {{this.participants.length}}
              {{if (eq this.participants.length 1) "person" "people"}}
            </p>
          </div>

          {{! Method tabs }}
          <div>
            <p class="ne-split-panel-title">Split Method</p>
            <div class="ne-split-tabs">
              <button type="button"
                class="ne-split-tab {{if (eq this.splitType 'EQUAL') 'ne-split-tab--active' ''}}"
                {{on "click" (fn this.setSplitType "EQUAL")}}>
                <span class="ne-split-tab-label">Equal</span>
                <span class="ne-split-tab-sub">÷ per person</span>
              </button>
              <button type="button"
                class="ne-split-tab {{if (eq this.splitType 'EXACT') 'ne-split-tab--active' ''}}"
                {{on "click" (fn this.setSplitType "EXACT")}}>
                <span class="ne-split-tab-label">Exact</span>
                <span class="ne-split-tab-sub">set amounts</span>
              </button>
              <button type="button"
                class="ne-split-tab {{if (eq this.splitType 'PERCENTAGE') 'ne-split-tab--active' ''}}"
                {{on "click" (fn this.setSplitType "PERCENTAGE")}}>
                <span class="ne-split-tab-label">Percent</span>
                <span class="ne-split-tab-sub">by %</span>
              </button>
              <button type="button"
                class="ne-split-tab {{if (eq this.splitType 'SHARES') 'ne-split-tab--active' ''}}"
                {{on "click" (fn this.setSplitType "SHARES")}}>
                <span class="ne-split-tab-label">Shares</span>
                <span class="ne-split-tab-sub">by ratio</span>
              </button>
            </div>
          </div>

          {{! Member rows }}
          <div class="ne-split-members">
            {{#each this.participants key="userId" as |p|}}
              <div class="ne-split-member-row">
                <div class="ne-split-member-avatar">
                  {{#if p.firstName}}{{p.firstName.[0]}}{{else}}?{{/if}}
                </div>
                <span class="ne-split-member-name">{{p.firstName}} {{p.lastName}}</span>
                {{#if (eq this.splitType "EQUAL")}}
                  <span class="ne-split-member-share">{{this.currencyCode}} {{this.equalSplitAmount}}</span>
                {{else if (eq this.splitType "EXACT")}}
                  <input type="number" step="0.01" min="0" placeholder="0.00"
                    class="share-input" value={{p.owedShare}}
                    {{on "input" (fn this.updateOwedShare p.userId)}} />
                {{else if (eq this.splitType "PERCENTAGE")}}
                  <input type="number" step="0.01" min="0" max="100" placeholder="%"
                    class="share-input" value={{p.owedShare}}
                    {{on "input" (fn this.updateOwedShare p.userId)}} />
                  <span class="split-unit">%</span>
                {{else if (eq this.splitType "SHARES")}}
                  <input type="number" step="1" min="0" placeholder="shares"
                    class="share-input" value={{p.owedShare}}
                    {{on "input" (fn this.updateOwedShare p.userId)}} />
                  <span class="split-unit">sh</span>
                {{/if}}
              </div>
            {{/each}}
          </div>

          {{! Balance status }}
          {{#if (eq this.splitType "EXACT")}}
            <div class="ne-split-balance {{if this.splitIsValid 'ne-split-balance--ok' 'ne-split-balance--warn'}}">
              {{#if this.splitIsValid}}
                ✓ Balanced
              {{else}}
                {{this.currencyCode}} {{this.remainingAmount}} remaining
              {{/if}}
            </div>
          {{else if (eq this.splitType "PERCENTAGE")}}
            <div class="ne-split-balance {{if this.splitIsValid 'ne-split-balance--ok' 'ne-split-balance--warn'}}">
              {{#if this.splitIsValid}}
                ✓ 100%
              {{else}}
                {{this.totalPercentageFormatted}}% of 100%
              {{/if}}
            </div>
          {{else if (eq this.splitType "SHARES")}}
            <p class="form-hint ne-split-hint">Total shares: {{this.totalShares}}</p>
          {{/if}}

        </div>{{! end ne-split-panel }}
      {{/if}}

    </form>
  </template>
}

export default RouteTemplate(ExpensesNewTemplate);
