class AddBlackAndWhiteVersionToPhysicalObject < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :black_and_white, :boolean
  end
end
