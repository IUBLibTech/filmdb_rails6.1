class UserUsernameToEmail < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :email_address, :string, unique: true
  end
end
