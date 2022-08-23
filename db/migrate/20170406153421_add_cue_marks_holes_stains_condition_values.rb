class AddCueMarksHolesStainsConditionValues < ActiveRecord::Migration[4.2]
  def up
    ControlledVocabulary.where("model_type='PhysicalObject' AND model_attribute=':value_condition' AND controlled_vocabularies.index > 3").each do |cv|
      cv.update(index: cv.index+1)
    end
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':value_condition', value: 'Cue Marks', index: 4).save

    ControlledVocabulary.where("model_type='PhysicalObject' AND model_attribute=':value_condition' AND controlled_vocabularies.index > 6").each do |cv|
      cv.update(index: cv.index+1)
    end
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':value_condition', value: 'Holes', index: 7).save

    ControlledVocabulary.where("model_type='PhysicalObject' AND model_attribute=':value_condition' AND controlled_vocabularies.index > 13").each do |cv|
      cv.update(index: cv.index+1)
    end
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':value_condition', value: 'Stains', index: 14).save
  end

  def down
    ControlledVocabulary.where(model_type: 'PhysicalObject', model_attribute: ':value_condition', value: 'Stains', index: 14).delete_all
    ControlledVocabulary.where("model_type='PhysicalObject' AND model_attribute=':value_condition' AND controlled_vocabularies.index > 13").each do |cv|
      cv.update(index: cv.index-1)
    end

    ControlledVocabulary.where(model_type: 'PhysicalObject', model_attribute: ':value_condition', value: 'Holes', index: 7).delete_all
    ControlledVocabulary.where("model_type='PhysicalObject' AND model_attribute=':value_condition' AND controlled_vocabularies.index > 6").each do |cv|
      cv.update(index: cv.index-1)
    end

    ControlledVocabulary.where(model_type: 'PhysicalObject', model_attribute: ':value_condition', value: 'Cue Marks', index: 4).delete_all
    ControlledVocabulary.where("model_type='PhysicalObject' AND model_attribute=':value_condition' AND controlled_vocabularies.index > 3").each do |cv|
      cv.update(index: cv.index-1)
    end

  end
end
