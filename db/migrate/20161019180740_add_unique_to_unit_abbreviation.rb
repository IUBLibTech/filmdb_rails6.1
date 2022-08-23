class AddUniqueToUnitAbbreviation < ActiveRecord::Migration[4.2]
  def change
    add_index :units, :abbreviation, unique: true
  end

end
