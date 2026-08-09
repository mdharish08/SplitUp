import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn, eq, and, not } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';
import ExpenseComments from 'splitup-ui/components/expense-comments';

function idEq(a, b) {
  return String(a) === String(b);
}

export class ExpensesExpenseTemplate extends Component {
  @service api;
  @service auth;
  @service router;
  @service toast;

  @tracked isEditing = false;
  @tracked isDeleting = false;
  @tracked isRestoring = false;
  @tracked errorMessage = null;
  @tracked isLoading = false;

  // Edit fields
  @tracked description = '';
  @tracked cost = '';
  @tracked currencyCode = 'USD';
  @tracked selectedCategoryId = '';
  @tracked splitType = 'EQUAL';

  currencies = ['USD', 'EUR', 'INR', 'GBP', 'JPY'];

  get expense() {
    return this.args.model.expense;
  }

  get comments() {
    return this.args.model.comments ?? [];
  }

  get categories() {
    return this.args.model.categories;
  }

  get friends() {
    return this.args.model.friends;
  }

  get currentUserId() {
    return Number(this.auth.userId);
  }

  get formattedDate() {
    const d = this.expense?.createdAt;
    if (!d) return '';
    return new Date(d).toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  }

  get formattedCost() {
    return `${this.expense?.currencyCode ?? ''} ${parseFloat(this.expense?.cost ?? 0).toFixed(2)}`;
  }

  get myShare() {
    const split = this.expense?.users?.find((u) => String(u.userId) === String(this.auth.userId));
    if (!split) return null;
    const paid = parseFloat(split.paidShare ?? 0);
    const owed = parseFloat(split.owedShare ?? 0);
    const net = parseFloat(split.netBalance ?? 0);
    return { paid, owed, net };
  }

  get isPayment() {
    return this.expense?.expenseType === 'PAYMENT';
  }

  get canManageExpense() {
    return String(this.expense?.paidBy) === String(this.currentUserId);
  }

  getUserName(userId) {
    const friend = this.friends.find((f) => String(f.id) === String(userId));
    if (friend) return `${friend.firstName} ${friend.lastName}`.trim();
    if (String(userId) === String(this.auth.userId)) return 'You';
    return `User ${userId}`;
  }

  get formattedSplitUsers() {
    const currency = this.expense?.currencyCode ?? '';
    return (this.expense?.users ?? []).map((u) => {
      const net = parseFloat(u.netBalance ?? 0);
      return {
        ...u,
        name: this.getUserName(u.userId),
        paidFormatted: `${currency} ${parseFloat(u.paidShare ?? 0).toFixed(2)}`,
        owedFormatted: `${currency} ${parseFloat(u.owedShare ?? 0).toFixed(2)}`,
        netFormatted: `${currency} ${net.toFixed(2)}`,
        netClass: net > 0 ? 'balance-positive' : net < 0 ? 'balance-negative' : 'balance-neutral',
        isMe: String(u.userId) === String(this.currentUserId),
      };
    });
  }

  @action startEdit() {
    const e = this.expense;
    this.description = e?.description ?? '';
    this.cost = String(e?.cost ?? '');
    this.currencyCode = e?.currencyCode ?? 'USD';
    this.selectedCategoryId = String(e?.category?.categoryId ?? '');
    this.isEditing = true;
    this.errorMessage = null;
  }

  @action cancelEdit() {
    this.isEditing = false;
    this.errorMessage = null;
  }

  @action updateField(field, event) {
    this[field] = event.target.value;
  }

  @action async saveEdit(event) {
    event.preventDefault();
    this.errorMessage = null;
    if (this.expense?.trashed) {
      this.errorMessage = 'Restore the expense before editing.';
      return;
    }

    const category = this.categories.find(
      (c) => String(c.categoryId) === String(this.selectedCategoryId),
    );
    if (!category) {
      this.errorMessage = 'Select a category';
      return;
    }

    this.isLoading = true;
    try {
      const body = {
        description: this.description,
        cost: parseFloat(this.cost),
        currencyCode: this.currencyCode,
        category,
        expenseType: this.expense.expenseType,
        groupId: this.expense.groupId ?? null,
        paidBy: this.expense.paidBy,
        users: this.expense.users,
      };
      const response = await this.api.put(`/api/v1/expense/${this.expense.id}`, body);
      if (response?.code !== 0) throw new Error(response?.error ?? 'Failed to update expense');
      this.toast?.success('Expense updated');
      this.isEditing = false;
      // Refresh model
      this.router.refresh('expenses.expense');
    } catch (e) {
      this.errorMessage = e.message;
    } finally {
      this.isLoading = false;
    }
  }

  @action async deleteExpense() {
    if (!confirm('Move this expense to deleted state? You can restore it later.')) return;
    this.isDeleting = true;
    try {
      await this.api.delete(`/api/v1/expense/${this.expense.id}`);
      this.toast?.success('Expense deleted');
      this.router.refresh('expenses.expense');
    } catch (e) {
      this.errorMessage = e.message;
    } finally {
      this.isDeleting = false;
    }
  }

  @action async restoreExpense() {
    this.isRestoring = true;
    this.errorMessage = null;
    try {
      await this.api.patch(`/api/v1/expense/${this.expense.id}/restore`, {});
      this.toast?.success('Expense restored');
      this.router.refresh('expenses.expense');
    } catch (e) {
      this.errorMessage = e.message;
    } finally {
      this.isRestoring = false;
    }
  }

  <template>
    <div class="page-content page-content--narrow">
    <div class="page-back">
      {{#if this.expense.groupId}}
        <LinkTo @route="groups.group" @model={{this.expense.groupId}}>← Group</LinkTo>
      {{else}}
        <LinkTo @route="expenses.index">← All Expenses</LinkTo>
      {{/if}}
    </div>

    {{#if this.expense}}
      <div class="expense-detail-card">
        <div class="expense-detail-header">
          <div class="expense-detail-icon">
            {{#if this.isPayment}}💸{{else}}💰{{/if}}
          </div>
          <div class="expense-detail-info">
            <h2 class="expense-detail-desc">{{this.expense.description}}</h2>
            <p class="expense-detail-amount">{{this.formattedCost}}</p>
            <p class="expense-detail-date">{{this.formattedDate}}</p>
            <p class="expense-detail-category">
              {{this.expense.category.categoryName}} ·
              {{this.expense.expenseType}}
            </p>
          </div>
          {{#if this.canManageExpense}}
            <div class="expense-detail-actions">
              {{#if this.expense.trashed}}
                <button
                  type="button"
                  class="btn-primary"
                  disabled={{this.isRestoring}}
                  {{on "click" this.restoreExpense}}
                >
                  {{if this.isRestoring "Restoring…" "Restore"}}
                </button>
              {{else}}
                <button type="button" class="btn-secondary" {{on "click" this.startEdit}}>
                  Edit
                </button>
                <button
                  type="button"
                  class="btn-danger"
                  disabled={{this.isDeleting}}
                  {{on "click" this.deleteExpense}}
                >
                  {{if this.isDeleting "Deleting…" "Delete"}}
                </button>
              {{/if}}
            </div>
          {{/if}}
        </div>

        {{#if this.errorMessage}}
          <div class="error-banner">{{this.errorMessage}}</div>
        {{/if}}

        {{#if this.expense.trashed}}
          <div class="error-banner">This expense is deleted. Restore it to edit or comment.</div>
        {{/if}}

        {{! ── Edit form ── }}
        {{#if (and this.isEditing (not this.expense.trashed))}}
          <form {{on "submit" this.saveEdit}} class="form-card expense-edit-form">
            <h3>Edit Expense</h3>
            <div class="form-group">
              <label for="edit-desc">Description</label>
              <input
                id="edit-desc"
                type="text"
                value={{this.description}}
                {{on "input" (fn this.updateField "description")}}
                required
              />
            </div>
            <div class="form-row">
              <div class="form-group">
                <label for="edit-cost">Amount</label>
                <input
                  id="edit-cost"
                  type="number"
                  step="0.01"
                  min="0"
                  value={{this.cost}}
                  {{on "input" (fn this.updateField "cost")}}
                  required
                />
              </div>
              <div class="form-group">
                <label for="edit-currency">Currency</label>
                <select id="edit-currency" {{on "change" (fn this.updateField "currencyCode")}}>
                  {{#each this.currencies as |code|}}
                    <option value={{code}} selected={{eq code this.currencyCode}}>{{code}}</option>
                  {{/each}}
                </select>
              </div>
            </div>
            <div class="form-group">
              <label for="edit-category">Category</label>
              <select id="edit-category" {{on "change" (fn this.updateField "selectedCategoryId")}}>
                <option value="">-- Select category --</option>
                {{#each this.categories as |cat|}}
                  <option
                    value={{cat.categoryId}}
                    selected={{idEq cat.categoryId this.selectedCategoryId}}
                  >{{cat.categoryName}}</option>
                {{/each}}
              </select>
            </div>
            <div class="form-actions">
              <button type="submit" class="btn-primary" disabled={{this.isLoading}}>
                {{if this.isLoading "Saving…" "Save Changes"}}
              </button>
              <button type="button" class="btn-secondary" {{on "click" this.cancelEdit}}>
                Cancel
              </button>
            </div>
          </form>
        {{/if}}

        {{! ── Split breakdown ── }}
        <div class="expense-split-breakdown">
          <h3>Split Breakdown</h3>
          {{#if this.formattedSplitUsers.length}}
            <table class="split-table">
              <thead>
                <tr>
                  <th>Person</th>
                  <th>Paid</th>
                  <th>Owes</th>
                  <th>Net</th>
                </tr>
              </thead>
              <tbody>
                {{#each this.formattedSplitUsers as |u|}}
                  <tr class={{if u.isMe "split-row-me" ""}}>
                    <td>{{u.name}}</td>
                    <td>{{u.paidFormatted}}</td>
                    <td>{{u.owedFormatted}}</td>
                    <td class={{u.netClass}}>{{u.netFormatted}}</td>
                  </tr>
                {{/each}}
              </tbody>
            </table>
          {{/if}}
        </div>

        {{#unless this.expense.trashed}}
          <ExpenseComments
            @expenseId={{this.expense.id}}
            @comments={{this.comments}}
          />
        {{/unless}}
      </div>
    {{else}}
      <div class="empty-state">
        <p>Expense not found.</p>
        <LinkTo @route="expenses.index" class="btn-secondary">Back to expenses</LinkTo>
      </div>
    {{/if}}
    </div>{{! end .page-content }}
  </template>
}

export default RouteTemplate(ExpensesExpenseTemplate);
