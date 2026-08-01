import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';
import { service } from '@ember/service';
import { eq } from '@ember/helper';

export default class Sidebar extends Component {
  @service api;
  @service auth;
  @service router;

  @tracked friends = [];
  @tracked groups = [];
  @tracked filterText = '';
  @tracked inviteEmail = '';
  @tracked inviteStatus = null; // null | 'added' | 'pending'
  @tracked inviteError = null;

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

  @action updateFilter(event) {
    this.filterText = event.target.value;
  }

  get filteredFriends() {
    const term = this.filterText.trim().toLowerCase();
    if (!term) return this.friends;
    return this.friends.filter((f) => {
      const name = `${f.firstName ?? ''} ${f.lastName ?? ''}`.toLowerCase();
      return name.includes(term) || (f.emailId ?? '').toLowerCase().includes(term);
    });
  }

  @action updateInviteEmail(event) {
    this.inviteEmail = event.target.value;
    this.inviteStatus = null;
    this.inviteError = null;
  }

  @action async sendInvite(event) {
    event.preventDefault();
    this.inviteError = null;
    this.inviteStatus = null;
    try {
      const response = await this.api.post(`/api/v1/friends/${this.auth.userId}`, {
        emailId: this.inviteEmail,
        currencyCode: 'USD',
      });
      if (response?.code !== 0) throw new Error(response?.error ?? 'Failed to add friend');

      const isPending = response.data?.registrationStatus === 'pending';
      this.inviteStatus = isPending ? 'pending' : 'added';
      this.inviteEmail = '';
      this.loadData();
    } catch (e) {
      this.inviteError = e.message;
    }
  }

  <template>
    <aside class="sidebar">
      <nav class="sidebar-nav">
        <LinkTo @route="index" class="sidebar-nav-link" activeClass="is-active">
          Dashboard
        </LinkTo>
        <LinkTo @route="expenses.index" class="sidebar-nav-link" activeClass="is-active">
          All expenses
        </LinkTo>
      </nav>

      <input
        type="text"
        class="sidebar-search"
        placeholder="Filter by name"
        value={{this.filterText}}
        {{on "input" this.updateFilter}}
      />

      <div class="sidebar-section">
        <div class="sidebar-section-header">
          <span>GROUPS</span>
          <LinkTo @route="groups.new" class="sidebar-add">+ add</LinkTo>
        </div>
        <ul class="sidebar-list">
          {{#each this.groups key="id" as |group|}}
            <li>
              <LinkTo @route="groups.group" @model={{group.id}} class="sidebar-item">
                {{group.name}}
              </LinkTo>
            </li>
          {{/each}}
        </ul>
      </div>

      <div class="sidebar-section">
        <div class="sidebar-section-header">
          <span>FRIENDS</span>
          <LinkTo @route="friends.new" class="sidebar-add">+ add</LinkTo>
        </div>
        <ul class="sidebar-list">
          {{#each this.filteredFriends key="emailId" as |friend|}}
            <li>
              {{#if friend.id}}
                {{! Registered user — navigate to their page }}
                <LinkTo @route="friends.friend" @model={{friend.id}} class="sidebar-item">
                  {{friend.firstName}} {{friend.lastName}}
                </LinkTo>
              {{else}}
                {{! Pending invite — not yet registered }}
                <span class="sidebar-item sidebar-item--pending">
                  <span class="sidebar-pending-email">{{friend.emailId}}</span>
                  <span class="sidebar-invited-badge">Invited</span>
                </span>
              {{/if}}
            </li>
          {{/each}}
        </ul>
      </div>

      <div class="invite-box">
        <p class="invite-title">Invite friends</p>
        {{#if (eq this.inviteStatus "added")}}
          <p class="invite-success">Friend added!</p>
        {{else if (eq this.inviteStatus "pending")}}
          <p class="invite-success">Invite sent! They'll be connected when they join.</p>
        {{/if}}
        {{#if this.inviteError}}
          <p class="invite-error">{{this.inviteError}}</p>
        {{/if}}
        <form {{on "submit" this.sendInvite}}>
          <input
            type="email"
            placeholder="Enter an email address"
            value={{this.inviteEmail}}
            {{on "input" this.updateInviteEmail}}
            required
          />
          <button type="submit">Send invite</button>
        </form>
      </div>
    </aside>
  </template>
}
