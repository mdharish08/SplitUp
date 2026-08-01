import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class AuthenticatedRoute extends Route {
  @service auth;
  @service router;

  beforeModel(transition) {
    if (!this.auth.isAuthenticated) {
      this.auth.attemptedTransition = transition;
      this.router.transitionTo('login');
    }
  }
}
