class PhysicalObjectCorrectGenerationPositiveColumnName < ActiveRecord::Migration[4.2]
  def up
    rename_column :physical_objects, :generation_positve, :generation_positive
  end
  def down
    rename_column :physical_objects, :generation_positive, :generation_positve
  end
end
