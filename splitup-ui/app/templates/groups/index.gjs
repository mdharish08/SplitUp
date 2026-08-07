import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';
import GroupCard from 'splitup-ui/components/group-card';

export const GroupsIndexTemplate = <template>
    <div class="page-content page-content--narrow">
      <div class="page-header">
        <div>
          <p class="page-eyebrow">Collective</p>
          <h1 class="page-title">Groups</h1>
        </div>
        <LinkTo @route="groups.new" class="btn-primary" style="margin-top:6px">+ New Group</LinkTo>
      </div>

      {{#if @model.groups.length}}
        <div class="groups-list">
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
    </div>
  </template>;

export default RouteTemplate(GroupsIndexTemplate);
