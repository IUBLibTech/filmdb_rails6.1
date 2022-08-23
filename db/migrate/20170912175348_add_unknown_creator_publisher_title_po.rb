class AddUnknownCreatorPublisherTitlePo < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.where(model_type: 'PhysicalObjectDate', value: 'Lab Date').update_all(value: 'Lab Processing')
    ControlledVocabulary.new(model_type: 'PhysicalObjectDate', model_attribute: ':type', value: 'Edited').save!
    ControlledVocabulary.new(model_type: 'PhysicalObjectDate', model_attribute: ':type', value: 'Received from Lab').save!
    ControlledVocabulary.new(model_type: 'PhysicalObjectDate', model_attribute: ':type', value: 'TBD').save!

    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'TBD').save!
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Unknown').save!

    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_publisher_role_type', value: 'TBD').save!
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_publisher_role_type', value: 'Unknown').save!
  end
end
