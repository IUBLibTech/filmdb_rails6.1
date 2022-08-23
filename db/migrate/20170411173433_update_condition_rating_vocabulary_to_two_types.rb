class UpdateConditionRatingVocabularyToTwoTypes < ActiveRecord::Migration[4.2]

  def up
    rename_column :controlled_vocabularies, :index, :menu_index
    ControlledVocabulary.reset_column_information
    ControlledVocabulary.where(model_type: 'PhysicalObject', model_attribute: ':condition_rating').update_all(model_attribute: ':overall_condition_rating')
    cr = ['1 - Minimal', '2 - Moderate', '3 - Heavy', '4 - Possibly Unplayable']
    cr.each_with_index do |cr, i|
      ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':rated_condition_rating', value: cr, menu_index: i).save
    end
  end

  def down
    ControlledVocabulary.where(model_type: 'PhysicalObject', model_attribute: ':rated_condition_rating').delete_all
    ControlledVocabulary.where(model_type: 'PhysicalObject', model_attribute: ':overall_condition_rating').update_all(model_attribute: ':condition_rating')
    rename_column :controlled_vocabularies, :menu_index, :index
  end

end
