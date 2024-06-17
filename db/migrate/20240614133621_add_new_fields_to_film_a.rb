class AddNewFieldsToFilmA < ActiveRecord::Migration[6.1]
  def change
    add_column :films, :color_bw_color_gaspar, :boolean
    add_column :films, :stock_ilford, :boolean
    add_column :films, :aspect_ratio_1_75_1, :boolean
  end
end
