class AddPhysicalObjectLanguageTypes < ActiveRecord::Migration[4.2]
  def change
    types = %w(Text Titles Voiceover)
    types.each_with_index do |t, i|
      ControlledVocabulary.new(model_type: "Language", model_attribute: ':language_type', value: t, menu_index: 5 + i).save!
    end
  end
end
