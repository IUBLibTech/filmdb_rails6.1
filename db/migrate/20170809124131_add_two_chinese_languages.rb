class AddTwoChineseLanguages < ActiveRecord::Migration[4.2]
  def change
	  ControlledVocabulary.new(model_type: 'Language', model_attribute: ':language', value: 'Chinese, Mandarin').save
	  ControlledVocabulary.new(model_type: 'Language', model_attribute: ':language', value: 'Chinese, Cantonese').save
  end
end
