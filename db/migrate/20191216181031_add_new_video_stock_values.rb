class AddNewVideoStockValues < ActiveRecord::Migration[4.2]

  NEW_VALS = ['BASF', 'JVC', 'Kodak', 'Memorex', 'Phillips', 'RCA']

  def up
    NEW_VALS.each do |v|
      ControlledVocabulary.new(model_type: 'Video', model_attribute: ':stock', value: v).save!
    end
  end

  def down
    ControlledVocabulary.where(model_type: 'Video', model_attribute: ':stock', value: NEW_VALS).delete_all
  end
end
