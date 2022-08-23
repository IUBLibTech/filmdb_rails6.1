class CreateBooleanConditions < ActiveRecord::Migration[4.2]
  def change
    create_table :boolean_conditions do |t|
      t.integer :physical_object_id, limit: 8
      t.string :type
      t.text :comment
      t.text :fixed_comment
      t.integer :fixed_user_id, limit: 8
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
