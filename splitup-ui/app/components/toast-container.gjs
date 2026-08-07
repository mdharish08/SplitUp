import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';

export default class ToastContainer extends Component {
  @service toast;

  @action dismiss(id) {
    this.toast.dismiss(id);
  }

  <template>
    <div class="toast-container">
      {{#each this.toast.toasts key="id" as |t|}}
        <div class="toast toast--{{t.type}}">
          <span class="toast-message">{{t.message}}</span>
          <button
            type="button"
            class="toast-close"
            {{on "click" (fn this.dismiss t.id)}}
          >×</button>
        </div>
      {{/each}}
    </div>
  </template>
}
