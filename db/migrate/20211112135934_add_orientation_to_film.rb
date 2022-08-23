class AddOrientationToFilm < ActiveRecord::Migration[4.2]
  def change
    add_column :films, :orientation_a_wind, :boolean
    add_column :films, :orientation_b_wind, :boolean
  end
end
