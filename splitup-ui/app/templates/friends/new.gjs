import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn, eq } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';

const CURRENCIES = ['USD', 'EUR', 'INR', 'GBP', 'JPY'];

export class FriendsNewTemplate extends Component {
  @service api;
  @service auth;
  @service router;

  currencies = CURRENCIES;

  @tracked emailId = '';
  @tracked currencyCode = 'USD';
  @tracked errorMessage = null;
  @tracked isLoading = false;
  @tracked inviteStatus = null; // null | 'added' | 'pending'
  @tracked invitedEmail = '';

  @action updateField(field, event) {
    this[field] = event.target.value;
  }

  @action resetForm() {
    this.emailId = '';
    this.currencyCode = 'USD';
    this.errorMessage = null;
    this.inviteStatus = null;
    this.invitedEmail = '';
  }

  @action async handleSubmit(event) {
    event.preventDefault();
    this.isLoading = true;
    this.errorMessage = null;
    this.inviteStatus = null;
    try {
      const response = await this.api.post(`/api/v1/friends/${this.auth.userId}`, {
        emailId: this.emailId,
        currencyCode: this.currencyCode,
      });
      if (response?.code !== 0) throw new Error(response?.error ?? 'Failed to add friend');

      const data = response.data;
      this.invitedEmail = this.emailId;

      if (data?.registrationStatus === 'pending') {
        // User doesn't exist yet — invite recorded
        this.inviteStatus = 'pending';
        this.emailId = '';
      } else {
        // User found and friendship created — go to their page
        this.router.transitionTo('friends.friend', data.id);
      }
    } catch (e) {
      this.errorMessage = e.message;
    } finally {
      this.isLoading = false;
    }
  }

  <template>
    <div class="page-content" style="max-width:580px;">
    <div class="page-back">
      <LinkTo @route="friends.index">← Friends</LinkTo>
    </div>

    <div style="margin-bottom:28px;">
      <p class="page-eyebrow">Connect</p>
      <h1 class="page-title">Add a Friend</h1>
    </div>

    {{#if (eq this.inviteStatus "pending")}}
      {{! ── Invite sent confirmation ── }}
      <div class="invite-sent-card">
        <div class="invite-sent-icon">✉️</div>
        <h3 class="invite-sent-title">Invite sent!</h3>
        <p class="invite-sent-body">
          <strong>{{this.invitedEmail}}</strong> isn't on SplitUp yet.
          When they sign up with this email, you'll automatically be connected as friends
          and any future expenses will sync immediately.
        </p>
        <div class="invite-sent-actions">
          <button type="button" class="btn-primary" {{on "click" this.resetForm}}>
            Add another friend
          </button>
          <LinkTo @route="index" class="btn-secondary">Back to Dashboard</LinkTo>
        </div>
      </div>
    {{else}}
      {{#if this.errorMessage}}
        <div class="error-banner">{{this.errorMessage}}</div>
      {{/if}}

      <form {{on "submit" this.handleSubmit}} class="form-card">
        <div class="form-group">
          <label for="friend-email">Email address</label>
          <input
            id="friend-email"
            type="email"
            value={{this.emailId}}
            {{on "input" (fn this.updateField "emailId")}}
            placeholder="friend@example.com"
            required
          />
          <p class="form-hint" style="margin-top: 6px;">
            If they're not on SplitUp yet, we'll send a connection invite for when they join.
          </p>
        </div>
        <div class="form-group">
          <label for="friend-currency">Default currency</label>
          <select id="friend-currency" {{on "change" (fn this.updateField "currencyCode")}}>
            {{#each this.currencies as |code|}}
              <option value={{code}} selected={{eq code this.currencyCode}}>{{code}}</option>
            {{/each}}
          </select>
        </div>

        <div class="form-actions">
          <button type="submit" class="btn-primary" disabled={{this.isLoading}}>
            {{if this.isLoading "Adding…" "Add Friend"}}
          </button>
          <LinkTo @route="friends.index" class="btn-secondary">Cancel</LinkTo>
        </div>
      </form>
    {{/if}}
    </div>{{! end .page-content }}
  </template>
}

export default RouteTemplate(FriendsNewTemplate);
