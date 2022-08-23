class AddOnSiteWellsToWorkflowStatusTemplate < ActiveRecord::Migration[4.2]
  def change
    # removed to get migration to work after removing WorkflowStatusLocation and WorkflowStatusTemplate models
    # WorkflowStatusTemplate.where(name: 'On Site').update_all(name: 'ALF Workflow', description: 'In workflow at ALF')
    # WorkflowStatusTemplate.new(name: 'Wells Workflow', sort_order: 6, description: 'In workflow at Wells 052').save
    #
    # WorkflowStatusLocation.where(facility: 'IULMIA-ALF', location_type: 'on_site').update_all(facility: 'ALF', location_type: 'ALF Workflow')
    # WorkflowStatusLocation.where(facility: 'IULMIA-Wells', location_type: 'on_site').update_all(facility: 'Wells 052', location_type: 'Wells Workflow')
  end
end
