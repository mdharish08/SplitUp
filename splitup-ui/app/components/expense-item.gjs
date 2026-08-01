import Component from '@glimmer/component';

export default class ExpenseItem extends Component {
  get youPaid() {
    return String(this.args.expense?.paidBy) === String(this.args.currentUserId);
  }

  get yourSplit() {
    return this.args.expense?.users?.find(
      (u) => String(u.userId) === String(this.args.currentUserId),
    );
  }

  get netBalance() {
    return parseFloat(this.yourSplit?.netBalance ?? 0);
  }

  get netBalanceClass() {
    if (this.netBalance > 0) return 'balance-positive';
    if (this.netBalance < 0) return 'balance-negative';
    return 'balance-neutral';
  }

  get netBalanceLabel() {
    if (this.netBalance > 0) return `+${this.netBalance.toFixed(2)}`;
    if (this.netBalance < 0) return this.netBalance.toFixed(2);
    return 'even';
  }

  get displayDate() {
    const d = this.args.expense?.createdAt;
    return d ? new Date(d).toLocaleDateString() : '';
  }

  get formattedCost() {
    const code = this.args.expense?.currencyCode ?? '';
    const amt = parseFloat(this.args.expense?.cost ?? 0).toFixed(2);
    return `${code} ${amt}`;
  }

  <template>
    <div class="expense-item">
      <div class="expense-category">{{@expense.category.categoryName}}</div>
      <div class="expense-details">
        <p class="expense-desc">{{@expense.description}}</p>
        <p class="expense-amount">{{this.formattedCost}}</p>
        <p class="expense-date">{{this.displayDate}}</p>
      </div>
      <div class="expense-split">
        {{#if this.youPaid}}
          <span class="badge-paid">you paid</span>
        {{/if}}
        {{#if this.yourSplit}}
          <span class={{this.netBalanceClass}}>{{this.netBalanceLabel}}</span>
        {{/if}}
      </div>
    </div>
  </template>
}
