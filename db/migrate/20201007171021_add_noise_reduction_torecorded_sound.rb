class AddNoiseReductionTorecordedSound < ActiveRecord::Migration[4.2]
  NOISE = ['Dolby A', 'Dolby B', 'Dolby C', 'Dolby S', 'Dolby SR', 'Dolby NR', 'Dolby HX', 'Dolby HX Pro', 'DBX',
           'DBX Type II', 'High Com', 'High Com II', 'adres', 'ANRS', 'DNL', 'DNR', 'CEDAR', 'None', 'Other']
  def up
    RecordedSound.transaction do
      add_column :recorded_sounds, :noise_reduction, :string
      NOISE.each do |nr|
        ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':noise_reduction', value: nr, active_status: true).save!
      end
    end
  end

  def down
    RecordedSound.transaction do
      remove_column :recorded_sounds, :noise_reduction, :string
      ControlledVocabulary.where(model_type: 'RecordedSound', model_attribute: ':noise_reduction').delete_all
    end
  end
end
