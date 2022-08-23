class RemoveAmatuerHomeMovieFromControlledVocabulary < ActiveRecord::Migration[4.2]
  def up
    ControlledVocabulary.where(model_type: 'TitleForm',model_attribute: ':form', value: 'Amateur - Home Movie').delete_all
  end

  def down
    ControlledVocabulary.new(model_type: 'TitleForm', model_attribute: ':form', value: 'Amateur - Home Movie', index: 7).save
  end
end
