import EmberRouter from '@embroider/router';
import config from 'splitup-ui/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  this.route('login');
  this.route('signup');
  this.route('friends', function () {
    this.route('new');
    this.route('friend', { path: '/:friend_id' });
  });
  this.route('groups', function () {
    this.route('new');
    this.route('group', { path: '/:group_id' });
  });
  this.route('expenses', function () {
    this.route('new');
  });
});
