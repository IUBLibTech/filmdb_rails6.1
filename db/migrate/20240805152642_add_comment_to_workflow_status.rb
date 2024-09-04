class AddCommentToWorkflowStatus < ActiveRecord::Migration[6.1]
  def change
    add_column :workflow_statuses, :comment, :text
  end
end
