class AddCedVideoGauge < ActiveRecord::Migration[4.2]
  def up
    ControlledVocabulary.new(model_type: 'Video', model_attribute: ':gauge', value: 'CED', active_status: true).save!
  end
  def down
    ControlledVocabulary.where(model_type'Video', model_attribute: ':gauge', value: 'CED', active_status: true).delete_all
  end
end