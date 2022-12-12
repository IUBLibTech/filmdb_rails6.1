class CreateEdgeCodes < ActiveRecord::Migration[6.1]
  def change
    create_table :edge_codes do |t|
      t.string :code, limit: 3
      t.integer :physical_object_id
      t.timestamps
    end
  end
end
