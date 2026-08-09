import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';
import { service } from '@ember/service';

const AVATAR_COLORS = ['#f59e0b','#10b981','#8b5cf6','#f43f5e','#0ea5e9','#f97316','#6366f1'];

function avatarColor(name) {
  let hash = 0;
  for (let i = 0; i < (name ?? '').length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

function initials(first, last) {
  return `${(first ?? '')[0] ?? ''}${(last ?? '')[0] ?? ''}`.toUpperCase();
}

export default class Sidebar extends Component {
  @service api;
  @service auth;
  @service router;
  @service toast;

  @tracked friends = [];
  @tracked groups = [];
  @tracked collapsed = localStorage.getItem('splitup-sidebar-collapsed') === 'true';

  constructor(owner, args) {
    super(owner, args);
    this.loadData();
    this.router.on('routeDidChange', this.loadData);
  }

  willDestroy() {
    super.willDestroy();
    this.router.off('routeDidChange', this.loadData);
  }

  loadData = async () => {
    if (!this.auth.isAuthenticated) return;
    const [friendsResponse, groupsResponse] = await Promise.all([
      this.api.get(`/api/v1/friends/${this.auth.userId}`),
      this.api.get(`/api/v1/user/${this.auth.userId}/group`),
    ]);
    this.friends = friendsResponse?.data ?? [];
    this.groups = groupsResponse?.data ?? [];
  };

  get userInitials() {
    return initials(this.auth.userFirstName, this.auth.userLastName) || (this.auth.userEmail ?? '?')[0].toUpperCase();
  }

  get userName() {
    const first = this.auth.userFirstName ?? '';
    const last = this.auth.userLastName ?? '';
    return `${first} ${last}`.trim() || (this.auth.userEmail ?? '');
  }

  get groupsWithBalance() {
    const userId = Number(this.auth.userId);
    return this.groups.map((g) => {
      const me = (g.members ?? []).find((m) => m.id === userId);
      const myBalance = parseFloat(me?.balance?.amount ?? 0) || 0;
      const absBalance = Math.abs(myBalance).toFixed(2);
      const currency = me?.balance?.currency_code ?? g.currencyCode ?? '';
      const balanceLabel = Math.abs(myBalance) >= 0.01 ? `${currency} ${absBalance}` : null;
      const balancePositive = myBalance > 0;
      const groupInitials = (g.name ?? '').slice(0, 2).toUpperCase();
      const color = avatarColor(g.name ?? '');
      return { ...g, myBalance, balanceLabel, balancePositive, groupInitials, color };
    });
  }

  get registeredFriends() {
    return this.friends.filter((f) => f.id && f.registrationStatus !== 'pending');
  }

  get pendingFriends() {
    return this.friends.filter((f) => f.registrationStatus === 'pending' || !f.id);
  }

  get hasFriendRows() {
    return this.registeredFriends.length || this.pendingFriends.length;
  }

  friendBalance(friend) {
    const amount = parseFloat(friend.balanceDto?.amount ?? 0);
    const currency = friend.balanceDto?.currency_code ?? '';
    if (Math.abs(amount) < 0.01) return null;
    return { label: `${currency} ${Math.abs(amount).toFixed(2)}`, positive: amount > 0 };
  }

  friendInitials(friend) {
    return initials(friend.firstName, friend.lastName);
  }

  friendColor(friend) {
    return avatarColor(`${friend.firstName ?? ''}${friend.lastName ?? ''}`);
  }

  @action logout() {
    this.auth.logout();
    this.router.transitionTo('login');
  }

  @action toggleCollapsed() {
    this.collapsed = !this.collapsed;
    localStorage.setItem('splitup-sidebar-collapsed', String(this.collapsed));
  }

  <template>
    <aside class="sidebar {{if this.collapsed 'is-collapsed'}}">
      {{! ── Brand ── }}
      <div class="sidebar-brand">
        <div class="sidebar-brand-icon">S</div>
        <span class="sidebar-brand-name">SplitUp</span>
        <button type="button" class="sidebar-collapse-btn" title="Toggle sidebar" {{on "click" this.toggleCollapsed}}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none"><path d="M10 3L6 8l4 5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
        </button>
      </div>

      {{! ── Main Nav ── }}
      <nav class="sidebar-nav">
        <p class="sidebar-section-label">Menu</p>
        <LinkTo @route="index" class="sidebar-nav-link" activeClass="is-active">
          <svg class="sidebar-nav-icon" viewBox="0 0 15 15" fill="none"><rect x="1" y="1" width="5.5" height="5.5" rx="1.2" fill="currentColor"/><rect x="8.5" y="1" width="5.5" height="5.5" rx="1.2" fill="currentColor"/><rect x="1" y="8.5" width="5.5" height="5.5" rx="1.2" fill="currentColor"/><rect x="8.5" y="8.5" width="5.5" height="5.5" rx="1.2" fill="currentColor"/></svg>
          Dashboard
        </LinkTo>
        <LinkTo @route="expenses.index" class="sidebar-nav-link" activeClass="is-active">
          <svg class="sidebar-nav-icon" viewBox="0 0 15 15" fill="none"><path d="M2 3.5h11M2 7.5h7M2 11.5h9" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>
          All Expenses
        </LinkTo>
        <LinkTo @route="friends.index" class="sidebar-nav-link" activeClass="is-active">
          <svg class="sidebar-nav-icon" viewBox="0 0 15 15" fill="none"><circle cx="5.5" cy="4.5" r="2.5" stroke="currentColor" stroke-width="1.4"/><path d="M1 13c0-2.5 2-4.5 4.5-4.5S10 10.5 10 13" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/><path d="M11.5 5.5c1 0 2 .9 2 2M13.5 13c0-1.6-.8-3-2.1-3.8" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/></svg>
          Friends
        </LinkTo>
        <LinkTo @route="groups.index" class="sidebar-nav-link" activeClass="is-active">
          <svg class="sidebar-nav-icon" viewBox="0 0 15 15" fill="none"><path d="M7.5 1.5L13 4.75v5.5L7.5 13.5L2 10.25V4.75L7.5 1.5Z" stroke="currentColor" stroke-width="1.4" stroke-linejoin="round"/></svg>
          Groups
        </LinkTo>
        <LinkTo @route="settings" class="sidebar-nav-link" activeClass="is-active">
          <svg class="sidebar-nav-icon" viewBox="0 0 15 15" fill="none"><circle cx="7.5" cy="7.5" r="2" stroke="currentColor" stroke-width="1.4"/><path d="M7.5 1v2M7.5 12v2M1 7.5h2M12 7.5h2M3.05 3.05l1.41 1.41M10.54 10.54l1.41 1.41M3.05 11.95l1.41-1.41M10.54 4.46l1.41-1.41" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/></svg>
          Settings
        </LinkTo>
      </nav>

      {{! ── Groups ── }}
      {{#if this.groupsWithBalance.length}}
        <div class="sidebar-divider"></div>
        <div class="sidebar-group-list">
          <p class="sidebar-section-label">Groups</p>
          {{#each this.groupsWithBalance key="id" as |group|}}
            <LinkTo @route="groups.group" @model={{group.id}} class="sidebar-group-item">
              <div class="sidebar-item-avatar" style="background:{{group.color}};color:#111110;">{{group.groupInitials}}</div>
              <span class="sidebar-item-name">{{group.name}}</span>
              {{#if group.balanceLabel}}
                <span class="sidebar-item-badge {{if group.balancePositive 'sidebar-item-badge--positive' 'sidebar-item-badge--negative'}}">{{group.balanceLabel}}</span>
              {{/if}}
            </LinkTo>
          {{/each}}
        </div>
      {{/if}}

      {{! ── Friends ── }}
      {{#if this.hasFriendRows}}
        <div class="sidebar-divider"></div>
        <div class="sidebar-friend-list">
          <p class="sidebar-section-label">Friends</p>
          {{#each this.registeredFriends key="emailId" as |friend|}}
            {{#let (this.friendBalance friend) as |bal|}}
              <LinkTo @route="friends.friend" @model={{friend.id}} class="sidebar-friend-item">
                <div class="sidebar-item-avatar" style="background:{{this.friendColor friend}};color:#111110;">{{this.friendInitials friend}}</div>
                <span class="sidebar-item-name">{{friend.firstName}} {{friend.lastName}}</span>
                {{#if bal}}
                  <span class="sidebar-item-badge {{if bal.positive 'sidebar-item-badge--positive' 'sidebar-item-badge--negative'}}">{{bal.label}}</span>
                {{/if}}
              </LinkTo>
            {{/let}}
          {{/each}}
          {{#each this.pendingFriends key="emailId" as |friend|}}
            <span class="sidebar-item--pending">
              <span class="sidebar-pending-email">{{friend.emailId}}</span>
              <span class="sidebar-invited-badge">Invited</span>
            </span>
          {{/each}}
        </div>
      {{/if}}

      {{! ── User Footer ── }}
      <div class="sidebar-footer">
        <div class="sidebar-user">
          <div class="sidebar-user-avatar">{{this.userInitials}}</div>
          <div class="sidebar-user-info">
            <p class="sidebar-user-name">{{this.userName}}</p>
            <p class="sidebar-user-email">{{this.auth.userEmail}}</p>
          </div>
          <button type="button" class="sidebar-logout-btn" title="Sign out" {{on "click" this.logout}}>
            <svg width="15" height="15" viewBox="0 0 15 15" fill="none"><path d="M9 10.5l3.5-3.5L9 3.5M12.5 7H5.5M5.5 12.5H2.5a.5.5 0 01-.5-.5V2.5a.5.5 0 01.5-.5h3" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/></svg>
          </button>
        </div>
      </div>
    </aside>
  </template>
}
