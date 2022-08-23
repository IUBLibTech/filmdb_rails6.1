class CapitalizeOtherInVideoStock < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.where(model_type: 'Video', model_attribute: ':stock', value: 'other').update_all(value: 'Other')
    Video.where(stock: 'other').update_all(stock: 'Other')
  end
end
