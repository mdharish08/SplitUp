import AuthenticatedRoute from '../authenticated';
import { service } from '@ember/service';

export default class ExpensesNewRoute extends AuthenticatedRoute {
  @service api;
  @service auth;

  queryParams = {
    groupId: { refreshModel: true },
  };

  async model(params) {
    const [friendsResponse, groupsResponse, categoriesResponse] = await Promise.all([
      this.api.get(`/api/v1/friends/${this.auth.userId}`),
      this.api.get(`/api/v1/user/${this.auth.userId}/group`),
      this.api.get('/api/v1/categories'),
    ]);
    return {
      friends: friendsResponse?.data ?? [],
      groups: groupsResponse?.data ?? [],
      categories: categoriesResponse?.data ?? [],
      preselectedGroupId: params.groupId || null,
    };
  }
}
