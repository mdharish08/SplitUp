import Component from '@glimmer/component';
import { service } from '@ember/service';
import { LinkTo } from '@ember/routing';

const AVATAR_COLORS = ['#f59e0b','#10b981','#8b5cf6','#f43f5e','#0ea5e9','#f97316','#6366f1'];
function groupColor(name) {
  let hash = 0;
  for (let i = 0; i < (name ?? '').length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

export default class GroupCard extends Component {
  @service auth;

  get memberCount() {
    return this.args.group?.members?.length ?? 0;
  }

  get groupInitials() {
    return (this.args.group?.name ?? '').slice(0, 2).toUpperCase();
  }

  get color() {
    return groupColor(this.args.group?.name ?? '');
  }

  get myBalance() {
    const userId = Number(this.auth.userId);
    const me = (this.args.group?.members ?? []).find((m) => m.id === userId);
    return parseFloat(me?.balance?.amount ?? 0) || 0;
  }

  get balanceLabel() {
    const b = this.myBalance;
    if (Math.abs(b) < 0.01) return 'settled up';
    const currency = this.args.group?.currencyCode ?? '';
    return `${currency} ${Math.abs(b).toFixed(2)}`;
  }

  get balanceLabelClass() {
    if (this.myBalance > 0) return 'balance-badge--positive';
    if (this.myBalance < 0) return 'balance-badge--negative';
    return 'balance-badge--neutral';
  }

  <template>
    <LinkTo @route="groups.group" @model={{@group.id}} class="group-list-row">
      <div class="group-list-icon" style="background:{{this.color}}; color:#111110;">
        {{this.groupInitials}}
      </div>
      <div class="group-list-info">
        <p class="group-list-name">{{@group.name}}</p>
        <p class="group-list-meta">{{this.memberCount}} members · {{@group.currencyCode}}</p>
      </div>
      <div class="group-list-balance">
        <span class="balance-badge {{this.balanceLabelClass}}">{{this.balanceLabel}}</span>
        <p class="group-list-balance-label">your balance</p>
      </div>
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="color:#d6d3d1; flex-shrink:0"><path d="M6 3l5 5-5 5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
    </LinkTo>
  </template>
}
