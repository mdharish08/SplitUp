import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class SignupRoute extends Route {
  @service auth;
  @service router;

  beforeModel() {
    if (this.auth.isAuthenticated) {
      this.router.transitionTo('index');
    }
  }
}
