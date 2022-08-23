class CreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |t|
      t.string :username, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.integer :role_mask, default: 0
      t.timestamps
    end
  end
end
