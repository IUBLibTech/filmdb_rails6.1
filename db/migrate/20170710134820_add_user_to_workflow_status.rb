class AddUserToWorkflowStatus < ActiveRecord::Migration[4.2]
  def change
    add_column :workflow_statuses, :created_by, :integer, limit: 8
  end
end
