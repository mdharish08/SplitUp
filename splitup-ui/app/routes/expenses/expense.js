import AuthenticatedRoute from '../authenticated';
import { service } from '@ember/service';

export default class ExpensesExpenseRoute extends AuthenticatedRoute {
  @service api;
  @service auth;

  async model({ expense_id }) {
    const [expenseResponse, categoriesResponse, friendsResponse] = await Promise.all([
      this.api.get(`/api/v1/expense/${expense_id}`),
      this.api.get('/api/v1/categories'),
      this.api.get(`/api/v1/friends/${this.auth.userId}`),
    ]);
    return {
      expense: expenseResponse?.data ?? expenseResponse,
      categories: categoriesResponse?.data ?? [],
      friends: friendsResponse?.data ?? [],
    };
  }
}
