class ChangeMauerSoundFieldToFormatType < ActiveRecord::Migration[4.2]
  def change
    rename_column :films, :sound_configuration_multi_track,:sound_format_optical_variable_area_maurer
  end
end
