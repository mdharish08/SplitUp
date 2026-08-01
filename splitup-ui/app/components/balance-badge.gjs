import Component from '@glimmer/component';

export default class BalanceBadge extends Component {
  get amount() {
    return this.args.balance?.amount ?? 0;
  }

  get currency() {
    return this.args.balance?.currency_code ?? '';
  }

  get isPositive() {
    return parseFloat(this.amount) > 0;
  }

  get isNegative() {
    return parseFloat(this.amount) < 0;
  }

  get displayAmount() {
    const abs = Math.abs(parseFloat(this.amount) || 0).toFixed(2);
    return `${this.currency} ${abs}`;
  }

  <template>
    {{#if this.isPositive}}
      <span class="balance-positive">owes you {{this.displayAmount}}</span>
    {{else if this.isNegative}}
      <span class="balance-negative">you owe {{this.displayAmount}}</span>
    {{else}}
      <span class="balance-neutral">settled up</span>
    {{/if}}
  </template>
}
