class NewRatedConditions < ActiveRecord::Migration[4.2]
  NEW_ONES = ['Creasing', 'Pocking']
  def up
    ControlledVocabulary.transaction do
      NEW_ONES.each do |n|
        ControlledVocabulary.new(model_type: 'Film', model_attribute: ':value_condition', value: n).save unless ControlledVocabulary.exists?(model_type: 'Film', model_attribute: ':value_condition', value: n)
      end
    end
  end

  def down
    ControlledVocabulary.transaction do
      NEW_ONES.each do |n|
        ControlledVocabulary.where(model_type: 'Film', model_attribute: ':value_condition', value: n).delete_all
      end
    end
  end
end
