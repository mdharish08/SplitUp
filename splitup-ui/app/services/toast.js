import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';

let nextId = 0;

export default class ToastService extends Service {
  @tracked toasts = [];

  _add(type, message, duration = 3500) {
    const id = ++nextId;
    this.toasts = [...this.toasts, { id, type, message }];
    setTimeout(() => this.dismiss(id), duration);
  }

  success(message) {
    this._add('success', message);
  }

  error(message) {
    this._add('error', message, 5000);
  }

  info(message) {
    this._add('info', message);
  }

  dismiss(id) {
    this.toasts = this.toasts.filter((t) => t.id !== id);
  }
}
