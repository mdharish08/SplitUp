import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn, eq } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';
import { avatarColor } from 'splitup-ui/utils/avatar-color';
import { htmlSafe } from '@ember/template';

const CURRENCIES = ['USD', 'EUR', 'INR', 'GBP', 'JPY'];

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

export class FriendsIndexTemplate extends Component {
  @service api;
  @service auth;
  @service router;

  currencies = CURRENCIES;

  @tracked searchText = '';
  @tracked showAddFriendModal = false;
  @tracked inviteEmail = '';
  @tracked inviteCurrency = 'USD';
  @tracked inviteError = null;
  @tracked inviteLoading = false;

  get allFriends() {
    return this.args.model.friends ?? [];
  }

  get registered() {
    return this.allFriends.filter(
      (f) => f.id != null && f.registrationStatus !== 'pending',
    );
  }

  get pending() {
    return this.allFriends.filter(
      (f) => f.registrationStatus === 'pending' || f.id == null,
    );
  }

  get filteredRegistered() {
    const term = this.searchText.trim().toLowerCase();
    if (!term) return this.registered;
    return this.registered.filter((f) =>
      `${f.firstName ?? ''} ${f.lastName ?? ''}`.toLowerCase().includes(term) ||
      (f.emailId ?? '').toLowerCase().includes(term),
    );
  }

  get filteredPending() {
    const term = this.searchText.trim().toLowerCase();
    if (!term) return this.pending;
    return this.pending.filter((f) =>
      (f.emailId ?? '').toLowerCase().includes(term),
    );
  }

  avatarStyle(friend) {
    return htmlSafe(`background-color: ${avatarColor(friend.id)}`);
  }

  @action updateSearch(e) { this.searchText = e.target.value; }
  @action openModal() { this.showAddFriendModal = true; this.inviteError = null; this.inviteEmail = ''; this.inviteCurrency = 'USD'; }
  @action closeModal() { this.showAddFriendModal = false; this.inviteError = null; }
  @action updateInviteField(field, e) { this[field] = e.target.value; }

  @action async submitInvite(e) {
    e.preventDefault();
    this.inviteLoading = true;
    this.inviteError = null;
    try {
      const response = await this.api.post(`/api/v1/friends/${this.auth.userId}`, {
        emailId: this.inviteEmail,
        currencyCode: this.inviteCurrency,
      });
      if (response?.code !== 0) throw new Error(response?.error ?? 'Failed to add friend');
      const data = response.data;
      this.closeModal();
      if (data?.registrationStatus !== 'pending') {
        this.router.transitionTo('friends.friend', data.id);
      } else {
        this.router.transitionTo('friends.index');
      }
    } catch (err) {
      this.inviteError = err.message;
    } finally {
      this.inviteLoading = false;
    }
  }

  <template>
    <div class="page-content page-content--narrow">
      <div class="page-header">
        <div>
          <p class="page-eyebrow">Network</p>
          <h1 class="page-title">Friends</h1>
        </div>
        <button type="button" class="btn-primary" style="margin-top:6px" {{on "click" this.openModal}}>+ Add Friend</button>
      </div>

      {{! ── Search bar ── }}
      <div class="filter-bar" style="margin-bottom:20px;">
        <div class="filter-search-wrap">
          <svg class="filter-search-icon" width="14" height="14" viewBox="0 0 14 14" fill="none"><circle cx="6" cy="6" r="4.5" stroke="currentColor" stroke-width="1.5"/><path d="M11 11l-2.5-2.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>
          <input
            type="text"
            placeholder="Search by name or email…"
            value={{this.searchText}}
            {{on "input" this.updateSearch}}
          />
        </div>
      </div>

      {{#if this.filteredRegistered.length}}
        <div class="friends-grid">
          {{#each this.filteredRegistered key="id" as |friend|}}
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

      {{#if this.filteredPending.length}}
        <p class="page-eyebrow" style="margin-top:32px; margin-bottom:14px">Invited — awaiting signup</p>
        <div style="display:flex; flex-direction:column; gap:8px;">
          {{#each this.filteredPending key="emailId" as |friend|}}
            <div class="friend-list-row" style="padding:14px 18px; background:#fff; border:1px solid var(--border); border-radius:10px;">
              <div class="friend-card-avatar" style="background:#f5f5f4; color:#a8a29e; width:36px; height:36px; font-size:.75rem;">?</div>
              <span style="flex:1; font-size:.9rem; color:var(--text-muted);">{{friend.emailId}}</span>
              <span class="sidebar-invited-badge" style="background:#f5f5f4; color:#78716c; padding:4px 10px; border-radius:6px; font-size:.75rem; font-weight:700;">Invited</span>
            </div>
          {{/each}}
        </div>
      {{/if}}

      {{#unless this.filteredRegistered.length}}
        {{#unless this.filteredPending.length}}
          <div class="empty-state">
            {{#if this.searchText}}
              <p>No friends match "{{this.searchText}}".</p>
            {{else}}
              <p>No friends yet.</p>
              <button type="button" class="btn-secondary" {{on "click" this.openModal}}>Add your first friend</button>
            {{/if}}
          </div>
        {{/unless}}
      {{/unless}}
    </div>

    {{! ── Add Friend Modal ── }}
    {{#if this.showAddFriendModal}}
      <div class="modal-overlay" {{on "click" this.closeModal}}>
        <div class="modal-card-sm" role="dialog" aria-modal="true">
          <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:20px;">
            <h2 style="margin:0; font-size:1.15rem; font-weight:800;">Add a Friend</h2>
            <button type="button" class="modal-close" style="background:none; border:none; cursor:pointer; font-size:1.4rem; color:var(--text-muted); line-height:1;" {{on "click" this.closeModal}}>×</button>
          </div>

          {{#if this.inviteError}}
            <div class="error-banner" style="margin-bottom:16px;">{{this.inviteError}}</div>
          {{/if}}

          <form {{on "submit" this.submitInvite}}>
            <div class="form-group">
              <label for="modal-friend-email">Email address</label>
              <input
                id="modal-friend-email"
                type="email"
                value={{this.inviteEmail}}
                {{on "input" (fn this.updateInviteField "inviteEmail")}}
                placeholder="friend@example.com"
                required
                autofocus
              />
              <p class="form-hint" style="margin-top:5px;">If they're not on SplitUp yet, we'll send an invite when they join.</p>
            </div>
            <div class="form-group">
              <label for="modal-friend-currency">Default currency</label>
              <select id="modal-friend-currency" {{on "change" (fn this.updateInviteField "inviteCurrency")}}>
                {{#each this.currencies as |code|}}
                  <option value={{code}} selected={{eq code this.inviteCurrency}}>{{code}}</option>
                {{/each}}
              </select>
            </div>
            <div class="form-actions" style="margin-top:24px;">
              <button type="submit" class="btn-primary" disabled={{this.inviteLoading}}>
                {{if this.inviteLoading "Sending…" "Send Invite"}}
              </button>
              <button type="button" class="btn-secondary" {{on "click" this.closeModal}}>Cancel</button>
            </div>
          </form>
        </div>
      </div>
    {{/if}}
  </template>
}

export default RouteTemplate(FriendsIndexTemplate);
