class AddProjectorBurnToFilm < ActiveRecord::Migration[6.1]
  def up
    ControlledVocabulary.create(model_type: "Film", model_attribute: ':value_condition', value: "Projector Burn")
    ControlledVocabulary.create(model_type: "Film", model_attribute: ':value_condition', value: "Stretch")
  end

  def down
    ControlledVocabulary.where(model_type: "Film", model_attribute: ':value_condition', value: "Projector Burn").delete_all
    ControlledVocabulary.create(model_type: "Film", model_attribute: ':value_condition', value: "Stretch").delete_all
  end
end
