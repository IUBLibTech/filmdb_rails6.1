class AddTechnicolorToFilmStock < ActiveRecord::Migration[8.0]
  def change
    add_column :films, :stock_technicolor, :boolean
  end
end
