class PhysicalObjectAccompanyingDocumentation < ActiveRecord::Migration[6.1]
  def change
    create_table :physical_object_accompanying_documentations do |t|
      t.integer :physical_object_id
      t.integer :accompanying_documentation_id
      t.timestamps
    end
  end
end
