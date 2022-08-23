class CreateDeleteLogEntries < ActiveRecord::Migration[4.2]
  def change
    create_table :delete_log_entries do |t|
      t.integer :table_id
      t.string :object_type
      t.string :human_readable_identifier
      t.string :who_deleted
      t.timestamps
    end
  end
end
