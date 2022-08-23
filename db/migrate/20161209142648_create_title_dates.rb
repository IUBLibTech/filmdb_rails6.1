class CreateTitleDates < ActiveRecord::Migration[4.2]
  def change
    create_table :title_dates do |t|
      t.integer :title_id, limit: 8
      t.string :date
      t.string :type
      t.timestamps null: false
    end
  end
end
