class AddCountryOfOriginToTitles < ActiveRecord::Migration[4.2]
  def change
    add_column :titles, :country_of_origin, :text
  end
end
