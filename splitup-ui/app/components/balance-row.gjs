import Component from '@glimmer/component';
import { LinkTo } from '@ember/routing';
import { htmlSafe } from '@ember/template';
import { avatarColor } from 'splitup-ui/utils/avatar-color';

export default class BalanceRow extends Component {
  get initials() {
    const first = this.args.friend?.firstName?.[0] ?? '';
    const last = this.args.friend?.lastName?.[0] ?? '';
    return (first + last).toUpperCase();
  }

  get avatarStyle() {
    // avatarColor() only ever returns a fixed hex value from our own palette, never user input.
    return htmlSafe(`background-color: ${avatarColor(this.args.friend?.id)};`);
  }

  get displayAmount() {
    return `${this.args.currency} ${Math.abs(this.args.amount).toFixed(2)}`;
  }

  get isOwed() {
    return this.args.amount > 0;
  }

  <template>
    <LinkTo @route="friends.friend" @model={{@friend.id}} class="balance-row">
      <span class="balance-row-avatar" style={{this.avatarStyle}}>{{this.initials}}</span>
      <span class="balance-row-name">{{@friend.firstName}} {{@friend.lastName}}</span>
      <span class="balance-row-amount {{if this.isOwed 'text-teal' 'text-orange'}}">
        <span class="balance-row-caption">{{if this.isOwed "owes you" "you owe"}}</span>
        {{this.displayAmount}}
      </span>
    </LinkTo>
  </template>
}
