import Route from '@ember/routing/route';
import { service } from '@ember/service';

export default class FriendsIndexRoute extends Route {
  @service router;

  beforeModel() {
    this.router.transitionTo('index');
  }
}
