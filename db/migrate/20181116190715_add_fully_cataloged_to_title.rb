class AddFullyCatalogedToTitle < ActiveRecord::Migration[4.2]
  def change
    add_column :titles, :fully_cataloged, :boolean
  end
end
