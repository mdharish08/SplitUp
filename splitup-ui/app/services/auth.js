import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { service } from '@ember/service';

// How many seconds before expiry we proactively show a warning
const EXPIRY_WARNING_THRESHOLD_S = 5 * 60; // 5 minutes

function decodeJwtPayload(token) {
  try {
    const segment = token.split('.')[1];
    return JSON.parse(atob(segment.replace(/-/g, '+').replace(/_/g, '/')));
  } catch {
    return null;
  }
}

export default class AuthService extends Service {
  @service toast;

  @tracked token = localStorage.getItem('splitup_token');
  @tracked userId = localStorage.getItem('splitup_userId');
  @tracked userEmail = localStorage.getItem('splitup_email');

  attemptedTransition = null;
  _expiryTimer = null;

  get isAuthenticated() {
    if (!this.token) return false;
    const payload = decodeJwtPayload(this.token);
    if (!payload) return false;
    return payload.exp * 1000 > Date.now();
  }

  get tokenExpiresAt() {
    if (!this.token) return null;
    const payload = decodeJwtPayload(this.token);
    return payload ? payload.exp * 1000 : null;
  }

  get isNearExpiry() {
    const exp = this.tokenExpiresAt;
    if (!exp) return false;
    return exp - Date.now() < EXPIRY_WARNING_THRESHOLD_S * 1000;
  }

  // Schedule a toast warning before expiry
  _scheduleExpiryWarning() {
    this._clearExpiryTimer();
    const exp = this.tokenExpiresAt;
    if (!exp) return;

    const warnAt = exp - EXPIRY_WARNING_THRESHOLD_S * 1000;
    const delay = warnAt - Date.now();

    if (delay > 0) {
      this._expiryTimer = setTimeout(() => {
        this.toast?.info('Your session expires in 5 minutes. Please save your work.');
      }, delay);
    }
  }

  _clearExpiryTimer() {
    if (this._expiryTimer) {
      clearTimeout(this._expiryTimer);
      this._expiryTimer = null;
    }
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
    this._scheduleExpiryWarning();
  }

  logout(reason = null) {
    this._clearExpiryTimer();
    this.token = null;
    this.userId = null;
    this.userEmail = null;
    localStorage.removeItem('splitup_token');
    localStorage.removeItem('splitup_userId');
    localStorage.removeItem('splitup_email');
    if (reason) {
      // Toast shown by caller or api service
    }
  }

  willDestroy() {
    this._clearExpiryTimer();
    super.willDestroy();
  }
}
