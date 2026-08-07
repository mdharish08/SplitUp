import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';
import ExpenseItem from 'splitup-ui/components/expense-item';

export class ExpensesIndexTemplate extends Component {
  @service auth;

  @tracked searchText = '';
  @tracked filterCategory = '';
  @tracked filterDateFrom = '';
  @tracked filterDateTo = '';
  @tracked sortOrder = 'desc'; // 'desc' | 'asc'

  @action updateSearch(event) {
    this.searchText = event.target.value;
  }

  @action updateFilterCategory(event) {
    this.filterCategory = event.target.value;
  }

  @action updateFilterDateFrom(event) {
    this.filterDateFrom = event.target.value;
  }

  @action updateFilterDateTo(event) {
    this.filterDateTo = event.target.value;
  }

  @action toggleSort() {
    this.sortOrder = this.sortOrder === 'desc' ? 'asc' : 'desc';
  }

  @action clearFilters() {
    this.searchText = '';
    this.filterCategory = '';
    this.filterDateFrom = '';
    this.filterDateTo = '';
  }

  get categories() {
    const cats = new Map();
    for (const e of this.args.model.expenses ?? []) {
      const name = e.category?.categoryName;
      if (name) cats.set(name, name);
    }
    return [...cats.keys()].sort();
  }

  get filteredExpenses() {
    let list = [...(this.args.model.expenses ?? [])];

    const term = this.searchText.trim().toLowerCase();
    if (term) {
      list = list.filter((e) =>
        (e.description ?? '').toLowerCase().includes(term) ||
        (e.category?.categoryName ?? '').toLowerCase().includes(term),
      );
    }

    if (this.filterCategory) {
      list = list.filter((e) => e.category?.categoryName === this.filterCategory);
    }

    if (this.filterDateFrom) {
      const from = new Date(this.filterDateFrom);
      list = list.filter((e) => new Date(e.createdAt) >= from);
    }

    if (this.filterDateTo) {
      const to = new Date(this.filterDateTo);
      to.setHours(23, 59, 59, 999);
      list = list.filter((e) => new Date(e.createdAt) <= to);
    }

    list.sort((a, b) => {
      const diff = new Date(b.createdAt) - new Date(a.createdAt);
      return this.sortOrder === 'desc' ? diff : -diff;
    });

    return list;
  }

  // Group by month
  get groupedExpenses() {
    const groups = [];
    let cur = null;
    for (const exp of this.filteredExpenses) {
      const d = new Date(exp.createdAt);
      const key = `${d.getFullYear()}-${d.getMonth()}`;
      const label = d.toLocaleDateString('en-US', { month: 'long', year: 'numeric' }).toUpperCase();
      if (!cur || cur.key !== key) {
        cur = { key, label, items: [] };
        groups.push(cur);
      }
      cur.items.push(exp);
    }
    return groups;
  }

  get hasActiveFilters() {
    return this.searchText || this.filterCategory || this.filterDateFrom || this.filterDateTo;
  }

  <template>
    <div class="page-content page-content--narrow">
      {{! ── Header ── }}
      <div class="page-header">
        <div>
          <p class="page-eyebrow">History</p>
          <h1 class="page-title">All Expenses</h1>
        </div>
        <LinkTo @route="expenses.new" class="btn-primary" style="margin-top:6px">
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none"><path d="M6 .5v11M.5 6h11" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
          Add expense
        </LinkTo>
      </div>

      {{! ── Filter bar ── }}
      <div class="filter-bar">
        <div class="filter-search-wrap">
          <svg class="filter-search-icon" width="14" height="14" viewBox="0 0 14 14" fill="none"><circle cx="6" cy="6" r="4.5" stroke="currentColor" stroke-width="1.5"/><path d="M11 11l-2.5-2.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>
          <input
            type="text"
            placeholder="Search expenses…"
            value={{this.searchText}}
            {{on "input" this.updateSearch}}
          />
        </div>
        <select class="filter-select" {{on "change" this.updateFilterCategory}}>
          <option value="">All categories</option>
          {{#each this.categories as |cat|}}
            <option value={{cat}} selected={{eq cat this.filterCategory}}>{{cat}}</option>
          {{/each}}
        </select>
        <input type="date" class="filter-select" value={{this.filterDateFrom}} {{on "change" this.updateFilterDateFrom}} title="From date" />
        <input type="date" class="filter-select" value={{this.filterDateTo}} {{on "change" this.updateFilterDateTo}} title="To date" />
        <button type="button" class="btn-secondary" {{on "click" this.toggleSort}}>
          {{if (eq this.sortOrder "desc") "Newest ↓" "Oldest ↑"}}
        </button>
        {{#if this.hasActiveFilters}}
          <button type="button" class="btn-secondary" {{on "click" this.clearFilters}}>Clear</button>
        {{/if}}
      </div>

      {{! ── Results ── }}
      {{#if this.filteredExpenses.length}}
        {{! Table header }}
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
            {{#each month.items as |expense|}}
              <ExpenseItem @expense={{expense}} @currentUserId={{this.auth.userId}} />
            {{/each}}
          </div>
        {{/each}}
      {{else}}
        <div class="empty-state">
          {{#if this.hasActiveFilters}}
            <p>No expenses match your filters.</p>
            <button type="button" class="btn-secondary" {{on "click" this.clearFilters}}>Clear filters</button>
          {{else}}
            <p>No expenses yet.</p>
            <LinkTo @route="expenses.new" class="btn-secondary">Add your first expense</LinkTo>
          {{/if}}
        </div>
      {{/if}}
    </div>{{! end .page-content }}
  </template>
}

export default RouteTemplate(ExpensesIndexTemplate);
