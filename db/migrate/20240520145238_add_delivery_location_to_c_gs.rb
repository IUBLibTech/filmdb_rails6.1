class AddDeliveryLocationToCGs < ActiveRecord::Migration[6.1]
  def change
    add_column :component_groups, :delivery_location, :string
  end
end
