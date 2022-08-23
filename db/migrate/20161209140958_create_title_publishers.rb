class CreateTitlePublishers < ActiveRecord::Migration[4.2]
  def up
    create_table :title_publishers do |t|
      t.integer :title_id, limit: 8
      t.string :name
      t.string :publisher_type
      t.timestamps
    end
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_publisher_role_type', value: 'Distributor', default: nil, index: 1).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_publisher_role_type', value: 'Presenter', default: nil, index: 2).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_publisher_role_type', value: 'Publisher', default: nil, index: 3).save
  end

  def down
    drop_table :title_publishers
    ControlledVocabulary.where(model_type: 'Title', model_attribute: ':title_publisher_role_type').delete_all
  end
end
