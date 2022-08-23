class AddValueConditionControlledVocabulary < ActiveRecord::Migration[4.2]
  def up
    values = [
        'Brittle', 'Broken', 'Channeling', 'Color Fade', 'Dirty', 'Edge Damage', 'Peeling', 'Perforation Damage', 'Rusty',
        'Scratches', 'Sound Track Damage', 'Splice Damage', 'Sticky', 'Tape Residue', 'Tearing', 'Warp', 'Water Damage'
    ]
    values.each_with_index do |v, i|
      ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':value_condition', value: v, index: i).save
    end
    values = [
        'Dusty', 'Lacquer Treated', 'Not on Core or Reel', 'Poor Wind', 'Replasticized', 'Spoking'
    ]
    values.each_with_index do |v, i|
      ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':boolean_condition', value: v, index: i).save
    end
  end
end
