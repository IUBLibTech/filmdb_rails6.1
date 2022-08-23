class CreateSpreadsheets < ActiveRecord::Migration[4.2]
  def change
    create_table :spreadsheets do |t|
      t.string :filename, null: false, unique: true
      t.timestamps
    end
  end
end
