class CorrectWorkflowStatusComponentGroupAssociation < ActiveRecord::Migration[4.2]
  def change
    PhysicalObject.where('component_group_id is not null').each do |p|
	    p.workflow_statuses.each do |ws|
		    if !WorkflowStatus::CLEAR_ACTIVE_COMPONENT_GROUP.include?(ws.status_name)
			    ws.update(component_group_id: p.active_component_group.id)
		    end
	    end
    end
  end
end
