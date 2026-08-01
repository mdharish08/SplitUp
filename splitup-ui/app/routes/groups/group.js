import AuthenticatedRoute from '../authenticated';
import { service } from '@ember/service';

export default class GroupsGroupRoute extends AuthenticatedRoute {
  @service api;
  @service auth;

  async model({ group_id }) {
    const [groupsResponse, expensesResponse, categoriesResponse] = await Promise.all([
      this.api.get(`/api/v1/user/${this.auth.userId}/group`),
      this.api.get(`/api/v1/expense/group/${group_id}`),
      this.api.get('/api/v1/categories'),
    ]);
    const allGroups = groupsResponse?.data ?? [];
    const group = allGroups.find((g) => String(g.id) === String(group_id));
    return {
      group,
      expenses: expensesResponse?.data ?? [],
      categories: categoriesResponse?.data ?? [],
    };
  }
}
