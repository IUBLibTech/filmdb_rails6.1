class AddDolbyUnknownToRecordedSound < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':noise_reduction', value: 'Dolby Unknown', active_status: true).save!
  end
end
