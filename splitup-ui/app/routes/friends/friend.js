import AuthenticatedRoute from '../authenticated';
import { service } from '@ember/service';

export default class FriendsFriendRoute extends AuthenticatedRoute {
  @service api;
  @service auth;

  async model({ friend_id }) {
    const [friendsResponse, expensesResponse, categoriesResponse] = await Promise.all([
      this.api.get(`/api/v1/friends/${this.auth.userId}`),
      this.api.get(`/api/v1/expense/user/${this.auth.userId}/friend/${friend_id}`),
      this.api.get('/api/v1/categories'),
    ]);
    const allFriends = friendsResponse?.data ?? [];
    const friend = allFriends.find((f) => String(f.id) === String(friend_id));
    return {
      friend,
      expenses: expensesResponse?.data ?? [],
      categories: categoriesResponse?.data ?? [],
    };
  }
}
