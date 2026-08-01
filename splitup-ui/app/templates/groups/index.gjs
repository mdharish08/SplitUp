import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';
import GroupCard from 'splitup-ui/components/group-card';

export const GroupsIndexTemplate = <template>
    <div class="page-header">
      <h2>Groups</h2>
      <LinkTo @route="groups.new" class="btn-primary">+ New Group</LinkTo>
    </div>

    {{#if @model.groups.length}}
      <div class="card-list">
        {{#each @model.groups as |group|}}
          <GroupCard @group={{group}} />
        {{/each}}
      </div>
    {{else}}
      <div class="empty-state">
        <p>No groups yet.</p>
        <LinkTo @route="groups.new" class="btn-secondary">Create your first group</LinkTo>
      </div>
    {{/if}}
  </template>;

export default RouteTemplate(GroupsIndexTemplate);
