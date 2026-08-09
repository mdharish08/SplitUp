import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';
import GroupCard from 'splitup-ui/components/group-card';

export class GroupsIndexTemplate extends Component {
  @tracked searchText = '';

  @action updateSearch(e) { this.searchText = e.target.value; }

  get filteredGroups() {
    const term = this.searchText.trim().toLowerCase();
    if (!term) return this.args.model.groups ?? [];
    return (this.args.model.groups ?? []).filter((g) =>
      (g.name ?? '').toLowerCase().includes(term),
    );
  }

  <template>
    <div class="page-content page-content--narrow">
      <div class="page-header">
        <div>
          <p class="page-eyebrow">Collective</p>
          <h1 class="page-title">Groups</h1>
        </div>
        <LinkTo @route="groups.new" class="btn-primary" style="margin-top:6px">+ New Group</LinkTo>
      </div>

      {{! ── Search bar ── }}
      <div class="filter-bar" style="margin-bottom:20px;">
        <div class="filter-search-wrap">
          <svg class="filter-search-icon" width="14" height="14" viewBox="0 0 14 14" fill="none"><circle cx="6" cy="6" r="4.5" stroke="currentColor" stroke-width="1.5"/><path d="M11 11l-2.5-2.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>
          <input
            type="text"
            placeholder="Search groups…"
            value={{this.searchText}}
            {{on "input" this.updateSearch}}
          />
        </div>
      </div>

      {{#if this.filteredGroups.length}}
        <div class="groups-list">
          {{#each this.filteredGroups as |group|}}
            <GroupCard @group={{group}} />
          {{/each}}
        </div>
      {{else}}
        <div class="empty-state">
          {{#if this.searchText}}
            <p>No groups match "{{this.searchText}}".</p>
          {{else}}
            <p>No groups yet.</p>
            <LinkTo @route="groups.new" class="btn-secondary">Create your first group</LinkTo>
          {{/if}}
        </div>
      {{/if}}
    </div>
  </template>
}

export default RouteTemplate(GroupsIndexTemplate);
