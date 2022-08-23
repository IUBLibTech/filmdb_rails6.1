class SimplifyWorkflowStatus < ActiveRecord::Migration[4.2]
  def change
    remove_columns :workflow_statuses, :workflow_status_template_id, :workflow_status_location_id
    drop_table :workflow_status_locations if table_exists? :workflow_status_locations
    drop_table :workflow_status_templates if table_exists? :workflow_status_templates

    add_column :workflow_statuses, :workflow_type, :string # Storage, In Workflow, Shipped
    add_column :workflow_statuses, :whose_workflow, :string # MDPI, IULMIA
    add_column :workflow_statuses, :status_name, :string # In Storage (Ingested), In Storage (Awaiting Ingest), Queued..., etc
    add_column :workflow_statuses, :component_group_id, :integer # This component group that initiated the workflow chain (starting with the que pull request)
	  add_column :workflow_statuses, :external_entity_id, :integer
  end
end
