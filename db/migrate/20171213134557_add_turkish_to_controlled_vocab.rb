class AddTurkishToControlledVocab < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.new(model_type: 'Language', model_attribute: ':language', value: 'Turkish').save
  end
end
