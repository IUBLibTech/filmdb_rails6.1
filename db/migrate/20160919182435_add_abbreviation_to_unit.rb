class AddAbbreviationToUnit < ActiveRecord::Migration[4.2]
  def change
    add_column :units, :abbreviation, :string, null: false
    add_column :units, :institution, :string, null: false
    add_column :units, :campus, :string
  end
end
