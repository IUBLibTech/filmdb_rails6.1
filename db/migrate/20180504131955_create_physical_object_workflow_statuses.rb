class CreatePhysicalObjectWorkflowStatuses < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :current_workflow_status_id, :integer, limit: 8
    add_index :physical_objects, :current_workflow_status_id

    pos = PhysicalObject.all
    count = pos.size
    pos.each_with_index do |p, i|
      puts "#{i} of #{count}"
      p.update(current_workflow_status_id: p.workflow_statuses.last.id)
    end
  end
end
