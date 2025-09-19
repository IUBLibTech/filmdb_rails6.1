class ChangeStorageTextValues < ActiveRecord::Migration[8.0]
  OLD_INGESTED = WorkflowStatus::OLD_IN_STORAGE_INGESTED
  OLD_AWAITING = WorkflowStatus::OLD_IN_STORAGE_AWAITING_INGEST
  NEW_INGESTED = WorkflowStatus::NEW_IN_STORAGE_INGESTED
  NEW_AWAITING = WorkflowStatus::NEW_IN_STORAGE_AWAITING_INGEST
  def up
    if WorkflowStatus::IN_STORAGE_INGESTED == OLD_INGESTED || WorkflowStatus::IN_STORAGE_AWAITING_INGEST == OLD_AWAITING
      raise "WorkflowStatus has the wrong values to complete the migration! See code comments in WorkflowStatus::IN_STORAGE_INGESTED"
    end
    WorkflowStatus.where(status_name: OLD_INGESTED).update_all(status_name: WorkflowStatus::IN_STORAGE_INGESTED)
    WorkflowStatus.where(status_name: OLD_AWAITING).update_all(status_name: WorkflowStatus::IN_STORAGE_AWAITING_INGEST)
  end

  def down
    if WorkflowStatus::IN_STORAGE_INGESTED == NEW_INGESTED || WorkflowStatus::IN_STORAGE_AWAITING_INGEST == NEW_AWAITING
      raise "WorkflowStatus has the wrong values to rollback the migration! See code comments in WorkflowStatus::IN_STORAGE_INGESTED"
    end
    WorkflowStatus.where(status_name: WorkflowStatus::NEW_IN_STORAGE_INGESTED).update_all(status_name: WorkflowStatus::IN_STORAGE_INGESTED)
    WorkflowStatus.where(status_name: WorkflowStatus::NEW_IN_STORAGE_AWAITING_INGEST).update_all(status_name: WorkflowStatus::IN_STORAGE_AWAITING_INGEST)
  end
end
