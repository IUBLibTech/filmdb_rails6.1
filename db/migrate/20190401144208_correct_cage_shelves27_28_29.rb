class CorrectCageShelves272829 < ActiveRecord::Migration[4.2]
  def change
      bcs = [40000003437763, 40000003437771, 40000003437789]
      cs = CageShelf.where(mdpi_barcode: bcs)
      cs.each do |cs|
        cs.physical_objects.each do |p|
          ws = WorkflowStatus.build_workflow_status(WorkflowStatus::SHIPPED_EXTERNALLY, p, true)
          p.workflow_statuses << ws
          p.current_workflow_status = ws
          p.save!
        end
      end
  end
end
