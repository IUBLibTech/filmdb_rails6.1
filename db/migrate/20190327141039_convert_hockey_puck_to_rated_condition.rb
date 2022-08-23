class ConvertHockeyPuckToRatedCondition < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':value_condition', value: 'Hockey Puck').save!
    ControlledVocabulary.where(model_type: 'PhysicalObject', model_attribute: ':boolean_condition', value: 'Hockey Puck').delete_all
  end
end
