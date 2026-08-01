import AuthenticatedRoute from '../authenticated';
import { service } from '@ember/service';

export default class ExpensesIndexRoute extends AuthenticatedRoute {
  @service api;
  @service auth;

  async model() {
    const response = await this.api.get(`/api/v1/expense/user/${this.auth.userId}`);
    return { expenses: response?.data ?? [] };
  }
}
