class AddSprocketDamageRatedCondition < ActiveRecord::Migration[6.1]
  def up
    ControlledVocabulary.new(model_type: "Film", model_attribute: ":value_condition", value: "Sprocket Damage").save! unless
      ControlledVocabulary.where(model_type: "Film", model_attribute: ":value_condition", value: "Sprocket Damage").exists?
  end

  def down
    ControlledVocabulary.where(model_type: "Film", model_attribute: ":value_condition", value: "Sprocket Damage").delete_all
  end
end
