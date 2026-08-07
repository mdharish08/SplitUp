import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn, eq } from '@ember/helper';
import { LinkTo } from '@ember/routing';

const GROUP_TYPE_OPTIONS = [
  { value: 'HOME',      label: 'Home',      icon: '🏠' },
  { value: 'TRIP',      label: 'Trip',      icon: '✈️' },
  { value: 'COUPLE',    label: 'Couple',    icon: '💑' },
  { value: 'APARTMENT', label: 'Apartment', icon: '🏢' },
  { value: 'OTHER',     label: 'Other',     icon: '📋' },
];

const CURRENCIES = ['USD', 'EUR', 'INR', 'GBP', 'JPY'];

export default class GroupForm extends Component {
  @service api;
  @service auth;
  @service router;

  groupTypeOptions = GROUP_TYPE_OPTIONS;
  currencies = CURRENCIES;

  @tracked name = '';
  @tracked groupType = 'OTHER';
  @tracked currencyCode = 'USD';
  @tracked description = '';
  @tracked memberSearch = '';
  @tracked members = [];
  @tracked showDropdown = false;
  @tracked errorMessage = null;
  @tracked isLoading = false;

  get filteredFriends() {
    const query = this.memberSearch.toLowerCase().trim();
    const addedIds = new Set(this.members.map((m) => m.id));
    if (!query) return [];
    return (this.args.friends ?? []).filter((f) => {
      if (f.id == null) return false; // pending invite — no account yet
      if (addedIds.has(f.id)) return false;
      const fullName = `${f.firstName ?? ''} ${f.lastName ?? ''}`.toLowerCase();
      return fullName.includes(query) || (f.emailId ?? '').toLowerCase().includes(query);
    });
  }

  get hasFriends() {
    return (this.args.friends ?? []).length > 0;
  }

  @action setGroupType(type) {
    this.groupType = type;
  }

  @action updateField(field, event) {
    this[field] = event.target.value;
  }

  @action onMemberSearchInput(event) {
    this.memberSearch = event.target.value;
    this.showDropdown = true;
  }

  @action selectFriend(friend) {
    if (this.members.find((m) => m.id === friend.id)) return;
    const name =
      `${friend.firstName ?? ''} ${friend.lastName ?? ''}`.trim() || friend.emailId;
    const initials =
      `${(friend.firstName?.[0] ?? '').toUpperCase()}${(friend.lastName?.[0] ?? '').toUpperCase()}` || '?';
    this.members = [...this.members, { id: friend.id, email: friend.emailId, name, initials }];
    this.memberSearch = '';
    this.showDropdown = false;
  }

  @action removeMember(memberId) {
    this.members = this.members.filter((m) => m.id !== memberId);
  }

  @action hideDropdown() {
    setTimeout(() => {
      this.showDropdown = false;
    }, 150);
  }

  @action async handleSubmit(event) {
    event.preventDefault();
    this.isLoading = true;
    this.errorMessage = null;
    try {
      const selfId = Number(this.auth.userId);
      const allMembers = [...this.members];
      if (!allMembers.find((m) => m.id === selfId)) {
        allMembers.unshift({ id: selfId, email: this.auth.userEmail });
      }
      const body = {
        name: this.name,
        groupType: this.groupType,
        currencyCode: this.currencyCode,
        description: this.description,
        members: allMembers,
      };
      const response = await this.api.post(
        `/api/v1/user/${this.auth.userId}/group`,
        body,
      );
      if (response?.code !== 0)
        throw new Error(response?.error ?? 'Failed to create group');
      this.router.transitionTo('groups.group', response.data.id);
    } catch (e) {
      this.errorMessage = e.message;
    } finally {
      this.isLoading = false;
    }
  }

  <template>
    <div class="page-content" style="max-width:640px;">
    <div class="page-back">
      <LinkTo @route="groups.index">← Groups</LinkTo>
    </div>

    <div style="margin-bottom:28px;">
      <p class="page-eyebrow">Create</p>
      <h1 class="page-title">New Group</h1>
      <p class="group-form-sub" style="color:var(--text-muted); font-size:.9rem; margin-top:6px;">Split expenses with people you choose</p>
    </div>

    {{#if this.errorMessage}}
      <div class="error-banner">{{this.errorMessage}}</div>
    {{/if}}

    <form {{on "submit" this.handleSubmit}} class="form-card group-form-card">

      {{! ── Group name ── }}
      <div class="form-group">
        <label for="gf-name">Group name</label>
        <div class="group-name-input-wrap">
          <span class="group-name-icon">
            {{#if this.name}}{{this.name.[0]}}{{else}}?{{/if}}
          </span>
          <input
            id="gf-name"
            type="text"
            class="group-name-input"
            value={{this.name}}
            {{on "input" (fn this.updateField "name")}}
            placeholder="e.g. Summer Trip 2025"
            required
          />
        </div>
      </div>

      {{! ── Group type as icon buttons ── }}
      <div class="form-group">
        <label>Type</label>
        <div class="group-type-options">
          {{#each this.groupTypeOptions as |opt|}}
            <button
              type="button"
              class="group-type-btn {{if (eq opt.value this.groupType) 'group-type-btn--active' ''}}"
              {{on "click" (fn this.setGroupType opt.value)}}
            >
              <span class="group-type-btn-icon">{{opt.icon}}</span>
              <span>{{opt.label}}</span>
            </button>
          {{/each}}
        </div>
      </div>

      {{! ── Currency ── }}
      <div class="form-group form-group--inline">
        <label for="gf-currency">Currency</label>
        <select id="gf-currency" {{on "change" (fn this.updateField "currencyCode")}}>
          {{#each this.currencies as |code|}}
            <option value={{code}} selected={{eq code this.currencyCode}}>{{code}}</option>
          {{/each}}
        </select>
      </div>

      {{! ── Description ── }}
      <div class="form-group">
        <label for="gf-desc">Description <span class="form-hint">(optional)</span></label>
        <input
          id="gf-desc"
          type="text"
          value={{this.description}}
          {{on "input" (fn this.updateField "description")}}
          placeholder="What's this group for?"
        />
      </div>

      {{! ── Members ── }}
      <div class="form-group">
        <label>Members</label>

        <div class="gf-member-list">
          {{! Current user (always included, not removable) }}
          <div class="gf-member-row gf-member-row--self">
            <div class="gf-member-avatar gf-member-avatar--self">
              {{(this.auth.userEmail.[0])}}
            </div>
            <div class="gf-member-info">
              <span class="gf-member-name">{{this.auth.userEmail}}</span>
              <span class="gf-member-you-tag">(you)</span>
            </div>
          </div>

          {{#each this.members as |member|}}
            <div class="gf-member-row">
              <div class="gf-member-avatar">{{member.initials}}</div>
              <div class="gf-member-info">
                <span class="gf-member-name">{{member.name}}</span>
                <span class="gf-member-email">{{member.email}}</span>
              </div>
              <button
                type="button"
                class="gf-member-remove"
                {{on "click" (fn this.removeMember member.id)}}
              >✕</button>
            </div>
          {{/each}}
        </div>

        {{#if this.hasFriends}}
          <div class="member-search-wrap" style="margin-top: 10px;">
            <input
              type="text"
              class="member-search-input"
              value={{this.memberSearch}}
              {{on "input" this.onMemberSearchInput}}
              {{on "blur" this.hideDropdown}}
              placeholder="Search friends by name or email…"
              autocomplete="off"
            />
            {{#if this.showDropdown}}
              {{#if this.filteredFriends.length}}
                <ul class="member-dropdown">
                  {{#each this.filteredFriends as |friend|}}
                    <li
                      class="member-dropdown-item"
                      {{on "mousedown" (fn this.selectFriend friend)}}
                    >
                      <span class="member-dropdown-name">
                        {{friend.firstName}} {{friend.lastName}}
                      </span>
                      <span class="member-dropdown-email">{{friend.emailId}}</span>
                    </li>
                  {{/each}}
                </ul>
              {{else if this.memberSearch}}
                <div class="member-dropdown member-dropdown--empty">
                  No friends match "{{this.memberSearch}}"
                </div>
              {{/if}}
            {{/if}}
          </div>
        {{else}}
          <p class="form-hint" style="margin-top: 8px;">
            No friends yet.
            <LinkTo @route="friends.new" class="link-teal">Add a friend</LinkTo>
            first to include them.
          </p>
        {{/if}}
      </div>

      <div class="form-actions">
        <button type="submit" class="btn-primary" disabled={{this.isLoading}}>
          {{if this.isLoading "Creating…" "Create Group"}}
        </button>
        <LinkTo @route="groups.index" class="btn-secondary">Cancel</LinkTo>
      </div>
    </form>
    </div>{{! end .page-content }}
  </template>
}
