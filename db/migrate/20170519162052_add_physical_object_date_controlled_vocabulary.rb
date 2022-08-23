class AddPhysicalObjectDateControlledVocabulary < ActiveRecord::Migration[4.2]
  def up
    ['Edge Code', 'Lab Date', 'Unknown'].each_with_index do |t, i|
      ControlledVocabulary.new(model_type: 'PhysicalObjectDate', model_attribute: ':type', value: t, menu_index: i, default: 0).save
    end
  end

  def down
    ControlledVocabulary.where(model_type: 'PhysicalObjectDate').delete_all
  end
end
