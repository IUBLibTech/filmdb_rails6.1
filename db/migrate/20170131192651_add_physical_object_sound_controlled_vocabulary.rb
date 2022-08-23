class AddPhysicalObjectSoundControlledVocabulary < ActiveRecord::Migration[4.2]
  def up
    vals = ["Sound", "Silent"]
    vals.each_with_index do |v, i|
      ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':sound', value: v, index: i).save
    end
  end

  def down
    ControlledVocabulary.where(model_type: 'PhysicalObject', model_attribute: 'sound').delete_all
  end
end
