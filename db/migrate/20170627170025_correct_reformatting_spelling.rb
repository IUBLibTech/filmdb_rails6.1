class CorrectReformattingSpelling < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.where(model_type: 'ComponentGroup', value: 'Reformating').update_all(value: 'Reformatting')
  end
end
