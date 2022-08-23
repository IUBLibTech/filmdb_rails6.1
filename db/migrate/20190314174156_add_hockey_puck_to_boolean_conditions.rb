class AddHockeyPuckToBooleanConditions < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':boolean_condition', value: 'Hockey Puck').save!
  end
end
