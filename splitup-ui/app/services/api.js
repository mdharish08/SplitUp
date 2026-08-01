import Service from '@ember/service';
import { service } from '@ember/service';

export default class ApiService extends Service {
  @service auth;
  @service router;

  async _fetch(path, options = {}) {
    const headers = { 'Content-Type': 'application/json' };
    if (this.auth.token) {
      headers['Authorization'] = `Bearer ${this.auth.token}`;
    }
    const response = await fetch(path, {
      ...options,
      headers: { ...headers, ...options.headers },
    });
    if (response.status === 401 || response.status === 403) {
      this.auth.logout();
      this.router.transitionTo('login');
      return null;
    }
    const text = await response.text();
    if (!text) return null;
    const json = JSON.parse(text);
    if (!response.ok) {
      throw new Error(json?.error ?? json?.message ?? `HTTP ${response.status}`);
    }
    return json;
  }

  get(path) {
    return this._fetch(path, { method: 'GET' });
  }

  post(path, body) {
    return this._fetch(path, {
      method: 'POST',
      body: JSON.stringify(body),
    });
  }
}
