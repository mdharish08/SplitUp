import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';

export class LoginTemplate extends Component {
  @service auth;
  @service router;

  @tracked email = '';
  @tracked password = '';
  @tracked errorMessage = null;
  @tracked isLoading = false;

  @action updateEmail(event) {
    this.email = event.target.value;
  }

  @action updatePassword(event) {
    this.password = event.target.value;
  }

  @action async handleSubmit(event) {
    event.preventDefault();
    this.isLoading = true;
    this.errorMessage = null;
    try {
      await this.auth.login(this.email, this.password);
      const attempted = this.auth.attemptedTransition;
      if (attempted) {
        this.auth.attemptedTransition = null;
        attempted.retry();
      } else {
        this.router.transitionTo('index');
      }
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
        <p class="auth-tagline">Split expenses, not friendships</p>

        {{#if this.errorMessage}}
          <div class="error-banner">{{this.errorMessage}}</div>
        {{/if}}

        <form {{on "submit" this.handleSubmit}}>
          <div class="form-group">
            <label for="email">Email</label>
            <input
              id="email"
              type="email"
              value={{this.email}}
              {{on "input" this.updateEmail}}
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
              {{on "input" this.updatePassword}}
              required
            />
          </div>
          <button type="submit" class="btn-primary btn-full" disabled={{this.isLoading}}>
            {{if this.isLoading "Signing in…" "Sign In"}}
          </button>
        </form>

        <p class="auth-footer">
          No account?
          <LinkTo @route="signup">Sign up</LinkTo>
        </p>
      </div>
    </div>
  </template>
}

export default RouteTemplate(LoginTemplate);
