class CreateTitleOriginalIdentifiers < ActiveRecord::Migration[4.2]
  def up
    create_table :title_original_identifiers do |t|
      t.integer :title_id, limit: 8
      t.string :identifier
      t.string :type
      t.timestamps
    end
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_original_identifier_type', value: 'Production number', default: nil, index: 1).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_original_identifier_type', value: 'Original catalog number', default: nil, index: 2).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_original_identifier_type', value: 'Uknown', default: nil, index: 3).save
  end

  def down
    drop_table :title_original_identifiers
    ControlledVocabulary.where(model_type: 'Title', model_attribute: ':title_original_identifier_type').delete_all
  end
end
