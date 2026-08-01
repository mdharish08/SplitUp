import Component from '@glimmer/component';
import { service } from '@ember/service';
import { LinkTo } from '@ember/routing';
import RouteTemplate from 'ember-route-template';
import ExpenseItem from 'splitup-ui/components/expense-item';

export class ExpensesIndexTemplate extends Component {
  @service auth;

  <template>
    <div class="page-header">
      <h2>All Expenses</h2>
      <LinkTo @route="expenses.new" class="btn-primary">+ Add Expense</LinkTo>
    </div>

    {{#if @model.expenses.length}}
      <div class="expense-list">
        {{#each @model.expenses as |expense|}}
          <ExpenseItem @expense={{expense}} @currentUserId={{this.auth.userId}} />
        {{/each}}
      </div>
    {{else}}
      <div class="empty-state">
        <p>No expenses yet.</p>
        <LinkTo @route="expenses.new" class="btn-secondary">Add your first expense</LinkTo>
      </div>
    {{/if}}
  </template>
}

export default RouteTemplate(ExpensesIndexTemplate);
