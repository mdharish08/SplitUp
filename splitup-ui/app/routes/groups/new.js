import AuthenticatedRoute from '../authenticated';
import { service } from '@ember/service';

export default class GroupsNewRoute extends AuthenticatedRoute {
  @service api;
  @service auth;

  async model() {
    const response = await this.api.get(`/api/v1/friends/${this.auth.userId}`);
    return { friends: response?.data ?? [] };
  }
}
