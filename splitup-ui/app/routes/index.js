import AuthenticatedRoute from './authenticated';
import { service } from '@ember/service';

export default class IndexRoute extends AuthenticatedRoute {
  @service api;
  @service auth;

  async model() {
    const [friendsResponse, categoriesResponse] = await Promise.all([
      this.api.get(`/api/v1/friends/${this.auth.userId}`),
      this.api.get('/api/v1/categories'),
    ]);
    return {
      friends: friendsResponse?.data ?? [],
      categories: categoriesResponse?.data ?? [],
    };
  }
}
