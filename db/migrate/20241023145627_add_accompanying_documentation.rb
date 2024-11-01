class AddAccompanyingDocumentation < ActiveRecord::Migration[6.1]
  def change
    create_table :accompanying_documentations do |t|
      t.string :location
      t.text :description
      t.integer :title_id
      t.integer :series_id
      t.timestamps
    end
  end
end
