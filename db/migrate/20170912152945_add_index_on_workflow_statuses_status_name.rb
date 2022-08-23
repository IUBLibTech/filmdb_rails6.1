class AddIndexOnWorkflowStatusesStatusName < ActiveRecord::Migration[4.2]
  def change
    add_index :workflow_statuses, :status_name
  end
end
