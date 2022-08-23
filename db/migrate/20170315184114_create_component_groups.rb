class CreateComponentGroups < ActiveRecord::Migration[4.2]
  def up
    create_table :component_groups do |t|
      t.integer :title_id, limit: 8, null: false
      t.string :group_type, null: false
      t.timestamps
    end
    cv = ['For Digitization', 'Preservation Copy', 'Research Copy', 'Screening Copy']
    cv.each_with_index do |term, i|
      ControlledVocabulary.new(model_type: 'ComponentGroup', model_attribute: ':group_type', value: term, index: i).save
    end
 end

  def down
    drop_table :component_groups
    ControlledVocabulary.where(model_type: 'ComponentGroup').delete_all
  end
end
