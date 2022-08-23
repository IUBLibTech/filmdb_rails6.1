class AdditionStocksForRecordedSound < ActiveRecord::Migration[4.2]
  NEW_ONES = ['3M', 'Agfa', 'Ampex', 'Maxwell', 'Scotch', 'Sony',  'TDK']
  def up
    NEW_ONES.each do |s|
      ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':stock', value: s).save!
    end
  end

  def down
    ControlledVocabulary.where(model_type: 'RecordedSound', model_attribute: ':stock', value: NEW_ONES).delete_all
  end
end
