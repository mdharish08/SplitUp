import Service from '@ember/service';
import { service } from '@ember/service';

export default class ApiService extends Service {
  @service auth;
  @service router;
  @service toast;

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
      const wasAuthenticated = this.auth.isAuthenticated;
      this.auth.logout();
      if (wasAuthenticated) {
        this.toast?.error('Your session has expired. Please sign in again.');
      }
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

  put(path, body) {
    return this._fetch(path, {
      method: 'PUT',
      body: JSON.stringify(body),
    });
  }

  patch(path, body) {
    return this._fetch(path, {
      method: 'PATCH',
      body: JSON.stringify(body),
    });
  }

  delete(path) {
    return this._fetch(path, { method: 'DELETE' });
  }
}
