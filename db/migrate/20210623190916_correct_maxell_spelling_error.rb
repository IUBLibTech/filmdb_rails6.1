class CorrectMaxellSpellingError < ActiveRecord::Migration[4.2]
  def up
    RecordedSound.where(stock: "Maxwell").update_all(stock: "Maxell")
    if ControlledVocabulary.where(model_type: "RecordedSound", model_attribute: ":stock", value: "Maxwell").size > 0
      ControlledVocabulary.where(model_type: "RecordedSound", model_attribute: ":stock", value: "Maxwell").update_all(value: "Maxell")
    end
  end

  def down
    RecordedSound.where(stock: "Maxell").update_all(stock: "Maxwell")
    if ControlledVocabulary.where(model_type: "RecordedSound", model_attribute: ":stock", value: "Maxell").size > 0
      ControlledVocabulary.where(model_type: "RecordedSound", model_attribute: ":stock", value: "Maxell").update_all(value: "Maxwell")
    end
  end
end
