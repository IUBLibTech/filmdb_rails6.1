class AddOpticalSoundFormatToPhysicalObject < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :sound_format_optical, :boolean
  end
end
