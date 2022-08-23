class AddOclcToTitleOriginalIdentifierVocab < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_original_identifier_type', value: 'OCLC Number', menu_index: '0', active_status: true).save!
  end
end
