import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';

function decodeJwtPayload(token) {
  try {
    const segment = token.split('.')[1];
    return JSON.parse(atob(segment.replace(/-/g, '+').replace(/_/g, '/')));
  } catch {
    return null;
  }
}

export default class AuthService extends Service {
  @tracked token = localStorage.getItem('splitup_token');
  @tracked userId = localStorage.getItem('splitup_userId');
  @tracked userEmail = localStorage.getItem('splitup_email');

  attemptedTransition = null;

  get isAuthenticated() {
    if (!this.token) return false;
    const payload = decodeJwtPayload(this.token);
    if (!payload) return false;
    return payload.exp * 1000 > Date.now();
  }

  async login(email, password) {
    const body = new URLSearchParams({ username: email, password });
    const response = await fetch('/api/v1/login', {
      method: 'POST',
      body,
    });
    if (!response.ok) {
      throw new Error('Invalid credentials');
    }
    const raw = response.headers.get('Authorization');
    if (!raw) {
      throw new Error('Server did not return a token');
    }
    const token = raw.startsWith('Bearer ') ? raw.slice(7) : raw;
    const payload = decodeJwtPayload(token);
    if (!payload) {
      throw new Error('Malformed token received');
    }
    this.token = token;
    this.userId = String(payload.userId);
    this.userEmail = payload.sub;
    localStorage.setItem('splitup_token', token);
    localStorage.setItem('splitup_userId', this.userId);
    localStorage.setItem('splitup_email', this.userEmail);
  }

  logout() {
    this.token = null;
    this.userId = null;
    this.userEmail = null;
    localStorage.removeItem('splitup_token');
    localStorage.removeItem('splitup_userId');
    localStorage.removeItem('splitup_email');
  }
}
