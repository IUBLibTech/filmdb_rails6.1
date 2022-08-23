class AddIndexOnPhysicalObjectIdToWorkflowStatuses < ActiveRecord::Migration[4.2]
  def change
    add_index :workflow_statuses, :physical_object_id
  end
end
