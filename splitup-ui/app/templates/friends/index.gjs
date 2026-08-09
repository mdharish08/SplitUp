import Component from '@glimmer/component';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';
import { avatarColor } from 'splitup-ui/utils/avatar-color';
import { htmlSafe } from '@ember/template';
import { or, eq } from '@ember/helper';

function initials(friend) {
  return ((friend.firstName?.[0] ?? '') + (friend.lastName?.[0] ?? '')).toUpperCase() || '?';
}

function balanceLabel(friend) {
  const amount = parseFloat(friend.balanceDto?.amount ?? 0);
  const currency = friend.balanceDto?.currency_code ?? '';
  if (Math.abs(amount) < 0.01) return { text: 'settled up', cls: 'balance-neutral' };
  if (amount > 0) return { text: `owes you ${currency} ${amount.toFixed(2)}`, cls: 'balance-positive' };
  return { text: `you owe ${currency} ${Math.abs(amount).toFixed(2)}`, cls: 'balance-negative' };
}

class FriendsIndexTemplate extends Component {
  get registered() {
    return (this.args.model.friends ?? []).filter(
      (f) => f.id != null && f.registrationStatus !== 'pending',
    );
  }

  get pending() {
    return (this.args.model.friends ?? []).filter(
      (f) => f.registrationStatus === 'pending' || f.id == null,
    );
  }

  avatarStyle(friend) {
    return htmlSafe(`background-color: ${avatarColor(friend.id)}`);
  }

  <template>
    <div class="page-content page-content--narrow">
      <div class="page-header">
        <div>
          <p class="page-eyebrow">Network</p>
          <h1 class="page-title">Friends</h1>
        </div>
        <LinkTo @route="friends.new" class="btn-primary" style="margin-top:6px">+ Add Friend</LinkTo>
      </div>

      {{#if this.registered.length}}
        <div class="friends-grid">
          {{#each this.registered key="id" as |friend|}}
            {{#let (balanceLabel friend) as |bal|}}
              <LinkTo @route="friends.friend" @model={{friend.id}} class="friend-card">
                <div class="friend-card-header">
                  <div class="friend-card-avatar" style="background:{{avatarColor friend.id}}; color:#111110;">
                    {{initials friend}}
                  </div>
                  <div>
                    <p class="friend-card-name">{{friend.firstName}} {{friend.lastName}}</p>
                    <p class="friend-card-email">{{friend.emailId}}</p>
                  </div>
                </div>
                <div class="friend-card-footer">
                  <span class="balance-badge {{if (eq bal.cls 'balance-positive') 'balance-badge--positive' (if (eq bal.cls 'balance-negative') 'balance-badge--negative' 'balance-badge--neutral')}}">{{bal.text}}</span>
                </div>
              </LinkTo>
            {{/let}}
          {{/each}}
        </div>
      {{/if}}

      {{#if this.pending.length}}
        <p class="page-eyebrow" style="margin-top:32px; margin-bottom:14px">Invited — awaiting signup</p>
        <div style="display:flex; flex-direction:column; gap:8px;">
          {{#each this.pending key="emailId" as |friend|}}
            <div class="friend-list-row" style="padding:14px 18px; background:#fff; border:1px solid var(--border); border-radius:10px;">
              <div class="friend-card-avatar" style="background:#f5f5f4; color:#a8a29e; width:36px; height:36px; font-size:.75rem;">?</div>
              <span style="flex:1; font-size:.9rem; color:var(--text-muted);">{{friend.emailId}}</span>
              <span class="sidebar-invited-badge" style="background:#f5f5f4; color:#78716c; padding:4px 10px; border-radius:6px; font-size:.75rem; font-weight:700;">Invited</span>
            </div>
          {{/each}}
        </div>
      {{/if}}

      {{#unless (or this.registered.length this.pending.length)}}
        <div class="empty-state">
          <p>No friends yet.</p>
          <LinkTo @route="friends.new" class="btn-secondary">Add your first friend</LinkTo>
        </div>
      {{/unless}}
    </div>
  </template>
}

export default RouteTemplate(FriendsIndexTemplate);
