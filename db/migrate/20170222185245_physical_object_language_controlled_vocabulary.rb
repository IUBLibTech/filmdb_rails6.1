class PhysicalObjectLanguageControlledVocabulary < ActiveRecord::Migration[4.2]
  def up
    languages = ['Arabic', 'Chinese', 'English', 'French', 'German', 'Hindi', 'Italian', 'Japanese', 'Portuguese', 'Russian', 'Spanish']
    types = ['Original Dialog', 'Dubbed Dialog', 'Captions', 'Subtitles', 'Intertitles']
    languages.each_with_index do |l, i|
      ControlledVocabulary.new(model_type: 'Language', model_attribute: ':language', value: l, index: i).save
    end
    types.each_with_index do |lt, i|
      ControlledVocabulary.new(model_type: 'Language', model_attribute: ':language_type', value: lt, index: i).save
    end
  end

  def down
    ControlledVocabulary.where(model_type: 'Language', model_attribute: ':language').delete_all
    ControlledVocabulary.where(model_type: 'Language', model_attribute: ':language_type').delete_all
  end
end
