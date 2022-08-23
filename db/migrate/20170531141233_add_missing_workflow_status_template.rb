class AddMissingWorkflowStatusTemplate < ActiveRecord::Migration[4.2]
  def change
    # removed to get migration to work after removing WorkflowStatusLocation and WorkflowStatusTemplate models
    # WorkflowStatusTemplate.new(name: 'Missing', sort_order: 5, description: "The item cannot be found in it's last location").save
  end
end
