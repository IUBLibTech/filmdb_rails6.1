class AddAmberToUsers < ActiveRecord::Migration[4.2]
  def change
    User.reset_column_information
    User.new(username: 'abertin', first_name: 'Amber', last_name: 'Bertin', email_address: 'abertin@iu.edu', can_delete: true, works_in_both_locations: true, active: true).save
  end
end
