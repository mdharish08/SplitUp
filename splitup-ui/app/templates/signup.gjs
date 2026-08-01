import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';

export class SignupTemplate extends Component {
  @service router;

  @tracked firstName = '';
  @tracked lastName = '';
  @tracked emailId = '';
  @tracked password = '';
  @tracked errorMessage = null;
  @tracked isLoading = false;

  @action updateField(field, event) {
    this[field] = event.target.value;
  }

  @action async handleSubmit(event) {
    event.preventDefault();
    this.isLoading = true;
    this.errorMessage = null;
    try {
      const response = await fetch('/api/v1/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          firstName: this.firstName,
          lastName: this.lastName,
          emailId: this.emailId,
          password: this.password,
        }),
      });
      const body = await response.json();
      if (body.code !== 0) throw new Error(body.error ?? 'Signup failed');
      this.router.transitionTo('login');
    } catch (e) {
      this.errorMessage = e.message;
    } finally {
      this.isLoading = false;
    }
  }

  <template>
    <div class="auth-page">
      <div class="auth-card">
        <h1 class="auth-logo">SplitUp</h1>
        <p class="auth-tagline">Create your account</p>

        {{#if this.errorMessage}}
          <div class="error-banner">{{this.errorMessage}}</div>
        {{/if}}

        <form {{on "submit" this.handleSubmit}}>
          <div class="form-row">
            <div class="form-group">
              <label for="firstName">First Name</label>
              <input
                id="firstName"
                type="text"
                value={{this.firstName}}
                {{on "input" (fn this.updateField "firstName")}}
                required
              />
            </div>
            <div class="form-group">
              <label for="lastName">Last Name</label>
              <input
                id="lastName"
                type="text"
                value={{this.lastName}}
                {{on "input" (fn this.updateField "lastName")}}
              />
            </div>
          </div>
          <div class="form-group">
            <label for="emailId">Email</label>
            <input
              id="emailId"
              type="email"
              value={{this.emailId}}
              {{on "input" (fn this.updateField "emailId")}}
              placeholder="you@example.com"
              required
            />
          </div>
          <div class="form-group">
            <label for="password">Password</label>
            <input
              id="password"
              type="password"
              value={{this.password}}
              {{on "input" (fn this.updateField "password")}}
              required
            />
          </div>
          <button type="submit" class="btn-primary btn-full" disabled={{this.isLoading}}>
            {{if this.isLoading "Creating account…" "Create Account"}}
          </button>
        </form>

        <p class="auth-footer">
          Already have an account?
          <LinkTo @route="login">Sign in</LinkTo>
        </p>
      </div>
    </div>
  </template>
}

export default RouteTemplate(SignupTemplate);
