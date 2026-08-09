import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn, eq } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';

const CAT_EMOJI = {
  'Food & Drink': '🍽', 'Groceries': '🛒', 'Travel': '✈️', 'Transport': '🚗',
  'Transportation': '🚗', 'Entertainment': '🎬', 'Activities': '🎭',
  'Utilities': '💡', 'Other': '•',
};

export class ExpensesIndexTemplate extends Component {
  @service auth;

  @tracked searchText = '';
  @tracked filterCategory = '';
  @tracked filterDateFrom = '';
  @tracked filterDateTo = '';
  @tracked sortOrder = 'desc';
  @tracked balanceFilter = 'all';

  @action updateSearch(event) { this.searchText = event.target.value; }
  @action updateFilterCategory(event) { this.filterCategory = event.target.value; }
  @action updateFilterDateFrom(event) { this.filterDateFrom = event.target.value; }
  @action updateFilterDateTo(event) { this.filterDateTo = event.target.value; }
  @action toggleSort() { this.sortOrder = this.sortOrder === 'desc' ? 'asc' : 'desc'; }
  @action clearFilters() {
    this.searchText = '';
    this.filterCategory = '';
    this.filterDateFrom = '';
    this.filterDateTo = '';
  }
  @action setBalanceFilter(filter) { this.balanceFilter = filter; }

  get categories() {
    const cats = new Map();
    for (const e of this.args.model.expenses ?? []) {
      const name = e.category?.categoryName;
      if (name) cats.set(name, name);
    }
    return [...cats.keys()].sort();
  }

  get friendMap() {
    const map = {};
    for (const f of this.args.model.friends ?? []) {
      map[String(f.id)] = `${f.firstName ?? ''} ${f.lastName ?? ''}`.trim();
    }
    return map;
  }

  get filteredExpenses() {
    const userId = String(this.auth.userId);
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

    if (this.balanceFilter === 'lent') {
      list = list.filter((e) => {
        const split = e.users?.find((u) => String(u.userId) === userId);
        return split && (parseFloat(split.netBalance ?? 0) || 0) > 0;
      });
    } else if (this.balanceFilter === 'owe') {
      list = list.filter((e) => {
        const split = e.users?.find((u) => String(u.userId) === userId);
        return split && (parseFloat(split.netBalance ?? 0) || 0) < 0;
      });
    }

    list.sort((a, b) => {
      const diff = new Date(b.createdAt) - new Date(a.createdAt);
      return this.sortOrder === 'desc' ? diff : -diff;
    });

    return list;
  }

  get enrichedExpenses() {
    const userId = String(this.auth.userId);
    const friendMap = this.friendMap;

    return this.filteredExpenses.map((exp) => {
      const d = new Date(exp.createdAt);
      const dayNum = d.getDate();
      const monthShort = d.toLocaleDateString('en-US', { month: 'short' }).toUpperCase();

      const catName = exp.category?.categoryName ?? 'Other';
      const catEmoji = CAT_EMOJI[catName] ?? '•';
      const isPayment = exp.expenseType === 'PAYMENT';

      const payerLabel = String(exp.paidBy) === userId
        ? 'you'
        : (friendMap[String(exp.paidBy)] ?? 'someone');

      const mySplit = exp.users?.find((u) => String(u.userId) === userId);
      let myShareLabel = 'not involved';
      let myShareType = 'neutral';
      let isInvolved = false;

      if (mySplit) {
        isInvolved = true;
        const net = parseFloat(mySplit.netBalance ?? 0) || 0;
        const cur = exp.currencyCode ?? '';
        if (net > 0) {
          myShareLabel = `lent ${cur} ${net.toFixed(2)}`;
          myShareType = 'positive';
        } else if (net < 0) {
          myShareLabel = `owe ${cur} ${Math.abs(net).toFixed(2)}`;
          myShareType = 'negative';
        } else {
          myShareLabel = 'settled';
          myShareType = 'neutral';
        }
      }

      const formattedCost = `${exp.currencyCode ?? ''} ${parseFloat(exp.cost ?? 0).toFixed(2)}`.trim();

      return { ...exp, dayNum, monthShort, catEmoji, isPayment, payerLabel, myShareLabel, myShareType, isInvolved, formattedCost };
    });
  }

  get groupedExpenses() {
    const groups = [];
    let cur = null;
    for (const exp of this.enrichedExpenses) {
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

  get totalLent() {
    const userId = String(this.auth.userId);
    let total = 0;
    for (const exp of this.args.model.expenses ?? []) {
      if (exp.expenseType === 'PAYMENT') continue;
      const split = exp.users?.find((u) => String(u.userId) === userId);
      if (!split) continue;
      const net = parseFloat(split.netBalance ?? 0) || 0;
      if (net > 0) total += net;
    }
    return total;
  }

  get totalOwed() {
    const userId = String(this.auth.userId);
    let total = 0;
    for (const exp of this.args.model.expenses ?? []) {
      if (exp.expenseType === 'PAYMENT') continue;
      const split = exp.users?.find((u) => String(u.userId) === userId);
      if (!split) continue;
      const net = parseFloat(split.netBalance ?? 0) || 0;
      if (net < 0) total += Math.abs(net);
    }
    return total;
  }

  get totalLentLabel() { return this.totalLent.toFixed(2); }
  get totalOwedLabel() { return this.totalOwed.toFixed(2); }
  get hasBalance() { return this.totalLent > 0 || this.totalOwed > 0; }

  get balanceCurrency() {
    for (const exp of this.args.model.expenses ?? []) {
      if (exp.currencyCode) return exp.currencyCode;
    }
    return '';
  }

  <template>
    <div class="expenses-screen">
      {{! ── Top bar ── }}
      <div class="expenses-topbar">
        <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:16px;">
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
            <button type="button" class="btn-secondary" {{on "click" this.clearFilters}}>Clear filters</button>
          {{/if}}
        </div>
      </div>

      {{! ── Two-panel body ── }}
      <div class="expenses-body">
        {{! ── Main list ── }}
        <div class="expenses-list">
          {{#if this.filteredExpenses.length}}
            {{#each this.groupedExpenses as |month|}}
              <div class="expense-month-group">
                <div class="expense-month-header">
                  <span class="expense-month-label">{{month.label}}</span>
                  <div class="expense-month-line"></div>
                </div>
                {{#each month.items as |exp|}}
                  {{#if exp.isPayment}}
                    <LinkTo @route="expenses.expense" @model={{exp.id}} class="expense-settle-row">
                      <span style="font-size:1.1rem;">💸</span>
                      <div style="flex:1;">
                        <p style="font-weight:700; color:var(--positive); font-size:.875rem; margin:0;">Settlement</p>
                        <p style="font-size:.8rem; color:var(--text-muted); margin:0;">{{exp.description}}</p>
                      </div>
                      <span style="font-weight:700; color:var(--positive); font-size:.875rem;">{{exp.formattedCost}}</span>
                    </LinkTo>
                  {{else}}
                    <LinkTo
                      @route="expenses.expense"
                      @model={{exp.id}}
                      class="expense-row expense-row-v2 {{unless exp.isInvolved 'not-involved'}}"
                    >
                      <div class="expense-date-stack">
                        <div class="expense-date-month">{{exp.monthShort}}</div>
                        <div class="expense-date-day">{{exp.dayNum}}</div>
                      </div>
                      <div class="expense-cat-icon">{{exp.catEmoji}}</div>
                      <div style="min-width:0;">
                        <p class="expense-row-desc" style="margin:0; font-weight:600; font-size:.9rem; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">{{exp.description}}</p>
                        <p class="expense-row-paid-by" style="margin:0;">{{exp.payerLabel}} paid</p>
                      </div>
                      <div style="text-align:right; min-width:0;">
                        <p class="expense-row-amount" style="margin:0;">{{exp.formattedCost}}</p>
                      </div>
                      <div style="text-align:right; min-width:0;">
                        <p class="expense-row-share expense-row-share--{{exp.myShareType}}" style="margin:0; font-size:.8rem;">{{exp.myShareLabel}}</p>
                      </div>
                    </LinkTo>
                  {{/if}}
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
        </div>

        {{! ── Balance panel ── }}
        <div class="expense-balance-panel">
          <p style="font-size:.7rem; font-weight:800; text-transform:uppercase; letter-spacing:.08em; color:var(--text-faint); margin:0 0 16px;">Your Balance</p>

          {{#if this.totalLent}}
            <div style="margin-bottom:16px;">
              <p style="font-size:.7rem; font-weight:700; text-transform:uppercase; letter-spacing:.05em; color:var(--text-faint); margin:0 0 3px;">You are owed</p>
              <p style="font-size:1.2rem; font-weight:900; color:var(--positive); margin:0;">{{this.balanceCurrency}} {{this.totalLentLabel}}</p>
            </div>
          {{/if}}

          {{#if this.totalOwed}}
            <div style="margin-bottom:16px;">
              <p style="font-size:.7rem; font-weight:700; text-transform:uppercase; letter-spacing:.05em; color:var(--text-faint); margin:0 0 3px;">You owe</p>
              <p style="font-size:1.2rem; font-weight:900; color:var(--negative); margin:0;">{{this.balanceCurrency}} {{this.totalOwedLabel}}</p>
            </div>
          {{/if}}

          {{#unless this.hasBalance}}
            <p style="color:var(--text-faint); font-size:.875rem; margin:0 0 16px;">All settled up!</p>
          {{/unless}}

          <div style="display:flex; flex-direction:column; gap:6px; margin-top:20px; border-top:1px solid var(--border); padding-top:16px;">
            <button
              type="button"
              class="{{if (eq this.balanceFilter 'all') 'btn-primary' 'btn-secondary'}}"
              style="font-size:.8rem; padding:6px 12px; text-align:left; width:100%;"
              {{on "click" (fn this.setBalanceFilter "all")}}
            >All expenses</button>
            <button
              type="button"
              class="{{if (eq this.balanceFilter 'lent') 'btn-primary' 'btn-secondary'}}"
              style="font-size:.8rem; padding:6px 12px; text-align:left; width:100%;"
              {{on "click" (fn this.setBalanceFilter "lent")}}
            >Lent money</button>
            <button
              type="button"
              class="{{if (eq this.balanceFilter 'owe') 'btn-primary' 'btn-secondary'}}"
              style="font-size:.8rem; padding:6px 12px; text-align:left; width:100%;"
              {{on "click" (fn this.setBalanceFilter "owe")}}
            >Owe money</button>
          </div>
        </div>
      </div>
    </div>
  </template>
}

export default RouteTemplate(ExpensesIndexTemplate);
