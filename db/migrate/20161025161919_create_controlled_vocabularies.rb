class CreateControlledVocabularies < ActiveRecord::Migration[4.2]
  def change
    create_table :controlled_vocabularies do |t|
      t.string :model_type
      t.string :model_attribute
      t.string :value
      t.boolean :default
      t.integer :index, default: 0
      t.timestamps
    end
  end
end
