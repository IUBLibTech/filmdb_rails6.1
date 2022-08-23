class CreateWorkflowStatuses < ActiveRecord::Migration[4.2]
  def change
    create_table :workflow_statuses do |t|
      t.integer :workflow_status_template_id, limit: 8
      t.integer :physical_object_id, limit: 8
      t.string :notes
      t.timestamps
    end
  end
end
