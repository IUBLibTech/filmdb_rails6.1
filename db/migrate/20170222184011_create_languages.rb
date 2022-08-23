class CreateLanguages < ActiveRecord::Migration[4.2]
  def up
    remove_column :physical_objects, :language_arabic
    remove_column :physical_objects, :language_chinese
    remove_column :physical_objects, :language_english
    remove_column :physical_objects, :language_french
    remove_column :physical_objects, :language_german
    remove_column :physical_objects, :language_hindi
    remove_column :physical_objects, :language_italian
    remove_column :physical_objects, :language_japanese
    remove_column :physical_objects, :language_portuguese
    remove_column :physical_objects, :language_russian
    remove_column :physical_objects, :language_spanish
    create_table :languages do |t|
      t.integer :physical_object_id, limit: 8
      t.string :language
      t.string :language_type
      t.timestamps
    end
  end

  def down
    drop_table :languages
    add_column :physical_objects, :language_arabic, :boolean
    add_column :physical_objects, :language_chinese, :boolean
    add_column :physical_objects, :language_english, :boolean
    add_column :physical_objects, :language_french, :boolean
    add_column :physical_objects, :language_german, :boolean
    add_column :physical_objects, :language_hindi, :boolean
    add_column :physical_objects, :language_italian, :boolean
    add_column :physical_objects, :language_japanese, :boolean
    add_column :physical_objects, :language_portuguese, :boolean
    add_column :physical_objects, :language_russian, :boolean
    add_column :physical_objects, :language_spanish, :boolean
  end
end
