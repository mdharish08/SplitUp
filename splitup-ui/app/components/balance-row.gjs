import Component from '@glimmer/component';
import { LinkTo } from '@ember/routing';

const AVATAR_COLORS = ['#f59e0b','#10b981','#8b5cf6','#f43f5e','#0ea5e9','#f97316','#6366f1'];

function avatarBg(id) {
  const hash = Number(id ?? 0);
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

export default class BalanceRow extends Component {
  get initials() {
    const first = this.args.friend?.firstName?.[0] ?? '';
    const last = this.args.friend?.lastName?.[0] ?? '';
    return (first + last).toUpperCase();
  }

  get color() {
    return avatarBg(this.args.friend?.id);
  }

  get displayAmount() {
    return `${this.args.currency} ${Math.abs(this.args.amount).toFixed(2)}`;
  }

  get isOwed() {
    return this.args.amount > 0;
  }

  get amountClass() {
    return this.isOwed ? 'balance-row-amount--owed' : 'balance-row-amount--owe';
  }

  <template>
    <LinkTo @route="friends.friend" @model={{@friend.id}} class="balance-row">
      <div class="balance-row-avatar" style="background:{{this.color}}; color:#111110;">{{this.initials}}</div>
      <div class="balance-row-info">
        <p class="balance-row-name">{{@friend.firstName}} {{@friend.lastName}}</p>
        <p class="balance-row-amount {{this.amountClass}}">
          {{if this.isOwed "owes you" "you owe"}} {{this.displayAmount}}
        </p>
      </div>
    </LinkTo>
  </template>
}
