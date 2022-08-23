class ChangeProductionDateToText < ActiveRecord::Migration[4.2]
  def change
    change_column :equipment_technologies, :production_year, :text
  end
end
