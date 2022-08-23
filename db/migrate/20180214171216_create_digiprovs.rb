class CreateDigiprovs < ActiveRecord::Migration[4.2]
  def change
    create_table :digiprovs do |t|
      t.integer :physical_object_id, limit: 8
      t.text :digital_provenance_text, limit: 65535
      t.timestamps
    end
  end
end
