class AddNewRatedConditionTypes < ActiveRecord::Migration[4.2]
  VALS = ["Redox blemishes", "Plasticizer exudation"]
  def up
    ControlledVocabulary.transaction do
      VALS.each do |v|
        ControlledVocabulary.new(model_type: "Film", model_attribute: ':value_condition', value: v).save!
      end
    end
  end

  def down
    ControlledVocabulary.transaction do
      VALS.each do |v|
        ControlledVocabulary.where(model_type: "Film", model_attribute: ':value_condition', value: v).delete_all
      end
    end
  end
end
