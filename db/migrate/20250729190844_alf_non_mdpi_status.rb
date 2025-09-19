class AlfNonMdpiStatus < ActiveRecord::Migration[8.0]
  # 19 physical objects were missed in 5/2024 when the WorkflowStatus#IN_WORKFLOW_ALF value was changed from "ALF (non MDPI)"
  # to "In Workflow (ALF)". This migration simply adds another WorkflowStatus#IN_WORKFLOW_ALF to the po's statuses (and sets
  # it current status to that). It does not change any non-current workflow statuses which have the previous value.
  def up
    bad = PhysicalObject.where_current_workflow_status_is(nil, nil, false, WorkflowStatusesHelper::OLD_IN_WORKFLOW_ALF)
    bad.each do |po|
      User.current_username = "jaalbrec"
      ws = WorkflowStatus.build_workflow_status(WorkflowStatusesHelper::IN_WORKFLOW_ALF, po, true)
      ws.comment = "WorkflowStatus corrected by developer 7/2025 from the OLD 'ALF (non MDPI)' value to the current 'In Workflow (ALF)'"
      po.workflow_statuses << ws
      po.current_workflow_status = ws
      po.save!
    end
  end

  def down
    # there is no back...
  end
end
