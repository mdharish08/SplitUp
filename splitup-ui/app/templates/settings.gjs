import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn, eq } from '@ember/helper';
import RouteTemplate from 'ember-route-template';

const CURRENCIES = ['USD', 'EUR', 'INR', 'GBP', 'JPY'];

class SettingsTemplate extends Component {
  @service auth;
  @service api;
  @service toast;

  currencies = CURRENCIES;

  // ── Profile fields ──
  @tracked firstName = '';
  @tracked lastName = '';
  @tracked defaultCurrency = 'USD';
  @tracked profileError = null;
  @tracked isSavingProfile = false;

  // ── Password fields ──
  @tracked currentPassword = '';
  @tracked newPassword = '';
  @tracked confirmPassword = '';
  @tracked passwordError = null;
  @tracked isSavingPassword = false;

  constructor(owner, args) {
    super(owner, args);
    this.loadProfile();
  }

  async loadProfile() {
    // Use raw fetch (not api service) so a 401/403 on this endpoint
    // does NOT trigger a global logout — this is a best-effort prefill.
    try {
      const token = this.auth.token;
      const response = await fetch(`/api/v1/user/${this.auth.userId}`, {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
      if (!response.ok) return; // silently skip — don't logout
      const text = await response.text();
      if (!text) return;
      const json = JSON.parse(text);
      const user = json?.data ?? json;
      if (user) {
        this.firstName = user.firstName ?? '';
        this.lastName = user.lastName ?? '';
        this.defaultCurrency = user.defaultCurrency ?? user.currencyCode ?? 'USD';
      }
    } catch {
      // best-effort; leave fields empty if endpoint is unavailable
    }
  }

  @action updateField(field, event) {
    this[field] = event.target.value;
  }

  @action async saveProfile(event) {
    event.preventDefault();
    this.profileError = null;
    this.isSavingProfile = true;
    try {
      const body = {
        firstName: this.firstName,
        lastName: this.lastName,
        defaultCurrency: this.defaultCurrency,
      };
      const response = await this.api.put(`/api/v1/user/${this.auth.userId}`, body);
      if (response?.code !== 0) throw new Error(response?.error ?? 'Failed to update profile');
      this.toast.success('Profile updated');
    } catch (e) {
      this.profileError = e.message;
    } finally {
      this.isSavingProfile = false;
    }
  }

  @action async changePassword(event) {
    event.preventDefault();
    this.passwordError = null;

    if (this.newPassword !== this.confirmPassword) {
      this.passwordError = 'New passwords do not match';
      return;
    }
    if (this.newPassword.length < 8) {
      this.passwordError = 'New password must be at least 8 characters';
      return;
    }

    this.isSavingPassword = true;
    try {
      const body = {
        currentPassword: this.currentPassword,
        newPassword: this.newPassword,
      };
      const response = await this.api.post(`/api/v1/user/${this.auth.userId}/change-password`, body);
      if (response?.code !== 0) throw new Error(response?.error ?? 'Failed to change password');
      this.toast.success('Password changed successfully');
      this.currentPassword = '';
      this.newPassword = '';
      this.confirmPassword = '';
    } catch (e) {
      this.passwordError = e.message;
    } finally {
      this.isSavingPassword = false;
    }
  }

  <template>
    <div class="page-content page-content--narrow">
      <div class="page-header">
        <div>
          <p class="page-eyebrow">Account</p>
          <h1 class="page-title">Settings</h1>
        </div>
      </div>

    {{! ── Profile ── }}
    <section class="settings-section">
      <h3 class="settings-section-title">Profile</h3>
      {{#if this.profileError}}
        <div class="error-banner">{{this.profileError}}</div>
      {{/if}}
      <form {{on "submit" this.saveProfile}} class="form-card">
        <div class="form-row">
          <div class="form-group">
            <label for="s-first-name">First Name</label>
            <input
              id="s-first-name"
              type="text"
              value={{this.firstName}}
              {{on "input" (fn this.updateField "firstName")}}
              required
            />
          </div>
          <div class="form-group">
            <label for="s-last-name">Last Name</label>
            <input
              id="s-last-name"
              type="text"
              value={{this.lastName}}
              {{on "input" (fn this.updateField "lastName")}}
            />
          </div>
        </div>
        <div class="form-group">
          <label for="s-email">Email</label>
          <input
            id="s-email"
            type="email"
            value={{this.auth.userEmail}}
            disabled
            class="input-disabled"
          />
          <p class="form-hint">Email cannot be changed.</p>
        </div>
        <div class="form-group">
          <label for="s-currency">Default Currency</label>
          <select id="s-currency" {{on "change" (fn this.updateField "defaultCurrency")}}>
            {{#each this.currencies as |code|}}
              <option value={{code}} selected={{eq code this.defaultCurrency}}>{{code}}</option>
            {{/each}}
          </select>
        </div>
        <div class="form-actions">
          <button type="submit" class="btn-primary" disabled={{this.isSavingProfile}}>
            {{if this.isSavingProfile "Saving…" "Save Profile"}}
          </button>
        </div>
      </form>
    </section>

    {{! ── Change Password ── }}
    <section class="settings-section">
      <h3 class="settings-section-title">Change Password</h3>
      {{#if this.passwordError}}
        <div class="error-banner">{{this.passwordError}}</div>
      {{/if}}
      <form {{on "submit" this.changePassword}} class="form-card">
        <div class="form-group">
          <label for="s-current-pw">Current Password</label>
          <input
            id="s-current-pw"
            type="password"
            value={{this.currentPassword}}
            {{on "input" (fn this.updateField "currentPassword")}}
            required
          />
        </div>
        <div class="form-group">
          <label for="s-new-pw">New Password</label>
          <input
            id="s-new-pw"
            type="password"
            value={{this.newPassword}}
            {{on "input" (fn this.updateField "newPassword")}}
            required
          />
        </div>
        <div class="form-group">
          <label for="s-confirm-pw">Confirm New Password</label>
          <input
            id="s-confirm-pw"
            type="password"
            value={{this.confirmPassword}}
            {{on "input" (fn this.updateField "confirmPassword")}}
            required
          />
        </div>
        <div class="form-actions">
          <button type="submit" class="btn-primary" disabled={{this.isSavingPassword}}>
            {{if this.isSavingPassword "Changing…" "Change Password"}}
          </button>
        </div>
      </form>
    </section>
    </div>{{! end .page-content }}
  </template>
}

export { SettingsTemplate };
export default RouteTemplate(SettingsTemplate);
