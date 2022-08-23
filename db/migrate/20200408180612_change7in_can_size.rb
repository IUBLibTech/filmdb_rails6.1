class Change7inCanSize < ActiveRecord::Migration[4.2]
  def up
    Film.transaction do
      Film.where(can_size: '7 in box').update_all(can_size: '7 inch box')
      ControlledVocabulary.where(model_type: "Film", model_attribute: ':can_size', value: '7 in box').update_all(value: '7 inch box')
    end
  end

  def down
    Film.transaction do
      Film.where(can_size: '7 inCH box').update_all(can_size: '7 in box')
      ControlledVocabulary.where(model_type: "Film", model_attribute: ':can_size', value: '7 inch box').update_all(value: '7 in box')
    end
  end
end
