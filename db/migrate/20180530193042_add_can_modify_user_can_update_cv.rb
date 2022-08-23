class AddCanModifyUserCanUpdateCv < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :can_edit_users, :boolean, default: false unless column_exists? :users, :can_edit_users
    add_column :users, :can_add_cv, :boolean, default: false unless column_exists? :users, :can_add_cv
    User.reset_column_information
    %w(jaalbrec carcurt).each do |u|
      user = User.where(username: u).first
      user.update!(can_edit_users: true, can_add_cv: true) unless user.nil?
    end
  end
end
