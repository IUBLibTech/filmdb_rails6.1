class CreatePhysicalObjects < ActiveRecord::Migration[4.2]
  def change
    create_table :physical_objects do |t|

      t.timestamps
    end
  end
end
