class SetCorrectComonentGroupTypes < ActiveRecord::Migration[4.2]
  def up
    ControlledVocabulary.where(model_type: 'ComponentGroup').delete_all
    ['Exhibition', 'Original Distribution', 'Reformating', 'Reference', 'Teaching', 'Training & Tours', 'Preservation Elements', 'Pre-Production Elements'].each_with_index do |gc, i|
      ControlledVocabulary.new(model_type: 'ComponentGroup', model_attribute: ':group_type', value: gc, index: i).save
    end
  end

  def down
    ControlledVocabulary.where(model_type: 'ComponentGroup').delete_all
    ['For Digitization', 'Preservation Copy', 'Research Copy', 'Screening Copy'].each_with_index do |gc, i|
      ControlledVocabulary.new(model_type: 'ComponentGroup', model_attribute: ':group_type', value: gc, index: i).save
    end
  end
end
