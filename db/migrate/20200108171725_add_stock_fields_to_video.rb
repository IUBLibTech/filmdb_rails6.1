class AddStockFieldsToVideo < ActiveRecord::Migration[4.2]
  NEW_VALS = %w(3M Eastman Quantegy TDK)

  def up
    ControlledVocabulary.transaction do
      NEW_VALS.each do |v|
        ControlledVocabulary.new(model_type: 'Video', model_attribute: ':stock', value: v).save! unless ControlledVocabulary.exists?(model_type: 'Video', model_attribute: ':stock', value: v)
      end
    end
  end

  def down
    ControlledVocabulary.transaction do
      ControlledVocabulary.where(model_type: 'Video', model_attribute: ':stock', value: NEW_VALS).delete_all
    end
  end

end
