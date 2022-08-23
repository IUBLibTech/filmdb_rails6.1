class ChangeDeaccessionedToDeaccession < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.where(model_type: 'PhysicalObject', model_attribute: ':overall_condition_rating', value: '6 - Deaccessioned').update_all(value: '6 - Deaccession')
    ControlledVocabulary.where(model_type: 'PhysicalObject', model_attribute: ':condition_type', value: '5 - Deaccessioned').delete_all
  end
end
