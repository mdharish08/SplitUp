import RouteTemplate from 'ember-route-template';
import GroupForm from 'splitup-ui/components/group-form';

export default RouteTemplate(
  <template>
    <GroupForm @friends={{@model.friends}} />
  </template>,
);
