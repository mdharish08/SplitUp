import Component from '@glimmer/component';
import { LinkTo } from '@ember/routing';

export default class GroupCard extends Component {
  get memberCount() {
    return this.args.group?.members?.length ?? 0;
  }

  <template>
    <LinkTo @route="groups.group" @model={{@group.id}} class="group-card">
      <div class="group-icon">{{@group.name.[0]}}</div>
      <div class="group-info">
        <p class="group-name">{{@group.name}}</p>
        <p class="group-meta">
          <span class="badge">{{@group.groupType}}</span>
          <span class="badge">{{@group.currencyCode}}</span>
          <span class="group-members">{{this.memberCount}} members</span>
        </p>
      </div>
    </LinkTo>
  </template>
}
