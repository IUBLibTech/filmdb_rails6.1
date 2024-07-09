class RemoveDeliveryLocationFromCgs < ActiveRecord::Migration[6.1]
  def change
    remove_column :component_groups, :delivery_location, :string
  end
end
