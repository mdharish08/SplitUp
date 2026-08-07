import Component from '@glimmer/component';
import { LinkTo } from '@ember/routing';

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
    if (this.netBalance > 0) return 'expense-row-share--owed';
    if (this.netBalance < 0) return 'expense-row-share--owe';
    return '';
  }

  get netBalanceLabel() {
    const code = this.args.expense?.currencyCode ?? '';
    if (this.netBalance > 0) return `you get back ${code} ${this.netBalance.toFixed(2)}`;
    if (this.netBalance < 0) return `you owe ${code} ${Math.abs(this.netBalance).toFixed(2)}`;
    return 'settled';
  }

  get displayDate() {
    const d = this.args.expense?.createdAt;
    if (!d) return '';
    const date = new Date(d);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  }

  get formattedCost() {
    const code = this.args.expense?.currencyCode ?? '';
    const amt = parseFloat(this.args.expense?.cost ?? 0).toFixed(2);
    return `${code} ${amt}`;
  }

  get categoryName() {
    return this.args.expense?.category?.categoryName ?? '—';
  }

  get paidByLabel() {
    return this.youPaid ? 'you' : `user ${this.args.expense?.paidBy ?? ''}`;
  }

  <template>
    <LinkTo @route="expenses.expense" @model={{@expense.id}} class="expense-row">
      <span class="expense-row-date">{{this.displayDate}}</span>
      <span>
        <span class="expense-cat-pill">{{this.categoryName}}</span>
      </span>
      <div class="expense-row-desc-wrap">
        <div class="expense-row-desc-line">
          <span class="expense-row-desc">{{@expense.description}}</span>
        </div>
        <p class="expense-row-paid-by">paid by {{this.paidByLabel}}</p>
      </div>
      <div class="expense-row-amount-wrap">
        <p class="expense-row-amount">{{this.formattedCost}}</p>
        {{#if this.yourSplit}}
          <p class="expense-row-share {{this.netBalanceClass}}">{{this.netBalanceLabel}}</p>
        {{/if}}
      </div>
    </LinkTo>
  </template>
}
