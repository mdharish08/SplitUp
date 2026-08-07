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
      {{! ── Left panel ── }}
      <div class="auth-left">
        <div class="auth-left-brand">
          <div class="auth-left-brand-icon">S</div>
          <span class="auth-left-brand-name">SplitUp</span>
        </div>
        <div>
          <p class="auth-left-eyebrow">Expense splitting, reimagined</p>
          <h1 class="auth-left-heading">Split smarter.<br/>Stay friends.</h1>
          <p class="auth-left-subtext">Track shared expenses, see who owes what, and settle up — no awkward conversations.</p>
        </div>
        <div class="auth-left-stats">
          <div class="auth-stat-card">
            <p class="auth-stat-value auth-stat-value--green">$162</p>
            <p class="auth-stat-label">you're owed</p>
          </div>
          <div class="auth-stat-card">
            <p class="auth-stat-value auth-stat-value--orange">$74</p>
            <p class="auth-stat-label">you owe</p>
          </div>
        </div>
      </div>

      {{! ── Right form ── }}
      <div class="auth-right">
        <div class="auth-form-wrap">
          <h2 class="auth-heading">Welcome back</h2>
          <p class="auth-subtext">Sign in to your SplitUp account</p>

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
            <div class="form-group" style="margin-bottom:28px">
              <label for="password">Password</label>
              <input
                id="password"
                type="password"
                value={{this.password}}
                {{on "input" this.updatePassword}}
                placeholder="••••••••"
                required
              />
            </div>
            <button type="submit" class="btn-primary btn-full" disabled={{this.isLoading}}>
              {{if this.isLoading "Signing in…" "Sign In →"}}
            </button>
          </form>

          <p class="auth-footer">
            No account?
            <LinkTo @route="signup" class="auth-link">Create account</LinkTo>
          </p>
          <p class="auth-footer-note">Secured with 256-bit encryption</p>
        </div>
      </div>
    </div>
  </template>
}

export default RouteTemplate(LoginTemplate);
