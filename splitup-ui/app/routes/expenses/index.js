import AuthenticatedRoute from '../authenticated';
import { service } from '@ember/service';

export default class ExpensesIndexRoute extends AuthenticatedRoute {
  @service api;
  @service auth;

  async model() {
    const [expensesResponse, friendsResponse] = await Promise.all([
      this.api.get(`/api/v1/expense/user/${this.auth.userId}`),
      this.api.get(`/api/v1/friends/${this.auth.userId}`),
    ]);
    return {
      expenses: expensesResponse?.data ?? [],
      friends: friendsResponse?.data ?? [],
    };
  }
}
