import AuthenticatedRoute from '../authenticated';
import { service } from '@ember/service';

export default class GroupsIndexRoute extends AuthenticatedRoute {
  @service api;
  @service auth;

  async model() {
    const response = await this.api.get(`/api/v1/user/${this.auth.userId}/group`);
    return { groups: response?.data ?? [] };
  }
}
