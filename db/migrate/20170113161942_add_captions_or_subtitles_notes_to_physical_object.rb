class AddCaptionsOrSubtitlesNotesToPhysicalObject < ActiveRecord::Migration[4.2]
  def change
    add_column :physical_objects, :captions_or_subtitles_notes, :text
  end
end
