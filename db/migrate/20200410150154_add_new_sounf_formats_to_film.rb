class AddNewSounfFormatsToFilm < ActiveRecord::Migration[4.2]
  def change
    add_column :films, :sound_format_optical_variable_area_bilateral, :boolean
    add_column :films, :sound_format_optical_variable_area_dual_bilateral, :boolean
    add_column :films, :sound_format_optical_variable_area_unilateral, :boolean
    add_column :films, :sound_format_optical_variable_area_dual_unilateral, :boolean
    add_column :films, :sound_format_optical_variable_area_rca_duplex, :boolean
    add_column :films, :sound_format_optical_variable_density_multiple_density, :boolean
  end
end
