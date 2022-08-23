class RenamePhysicalObjectCvToFilm < ActiveRecord::Migration[4.2]
  def up
    ControlledVocabulary.transaction do
      ControlledVocabulary.where(model_type: 'PhysicalObject').update_all(model_type: 'Film')
    end
  end

  def down
    ControlledVocabulary.transaction do
      ControlledVocabulary.where(model_type: 'Film').update_all(model_type: 'PhysicalObject')
    end
  end
end
