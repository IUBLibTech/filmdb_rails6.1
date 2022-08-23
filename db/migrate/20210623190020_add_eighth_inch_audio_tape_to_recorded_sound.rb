class AddEighthInchAudioTapeToRecordedSound < ActiveRecord::Migration[4.2]
  def up
    unless ControlledVocabulary.where(model_type: "RecordedSound", model_attribute: ":gauge", value: "1/8 inch audio tape").size > 0
      ControlledVocabulary.new(model_type: "RecordedSound", model_attribute: ":gauge", value: "1/8 inch audio tape").save
    end
  end

  def down
    if ControlledVocabulary.where(model_type: "RecordedSound", model_attribute: ":gauge", value: "1/8 inch audio tape").size > 0
      ControlledVocabulary.where(model_type: "RecordedSound", model_attribute: ":gauge", value: "1/8 inch audio tape").delete_all
    end
  end
end
