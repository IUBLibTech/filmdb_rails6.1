class FirstChangeToWorkflowStatuses < ActiveRecord::Migration[4.2]
  def change
    WorkflowStatus.all.delete_all
  end
end
