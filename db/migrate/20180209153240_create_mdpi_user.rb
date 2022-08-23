class CreateMdpiUser < ActiveRecord::Migration[4.2]
  def up
    User.reset_column_information
    User.new(username: 'filmdb', first_name: "Filmdb", last_name: "User", active: true,
             created_in_spreadsheet: 0, can_delete: false, can_update_physical_object_location: false,
             email_address: 'filmdb@indiana.edu').save!
  end

  def down
    # there is no spoon
  end
end
