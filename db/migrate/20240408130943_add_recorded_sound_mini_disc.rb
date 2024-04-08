class AddRecordedSoundMiniDisc < ActiveRecord::Migration[6.1]
  def change
    if ControlledVocabulary.where(model_attribute: "RecordedSound", model_attribute: ":gauge", value: "MiniDisc").size == 0
      ControlledVocabulary.new(model_type: "RecordedSound", model_attribute: ":gauge", value: "MiniDisc", menu_index: 0, active_status: 1).save
    end
    add_column :equipment_technologies, :recorded_sound_gauge_minidisc, :boolean
  end
end
