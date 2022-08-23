class AddGenerationNotesToRecordedSound < ActiveRecord::Migration[4.2]
  def change
    add_column :recorded_sounds, :generation_notes, :text
  end
end
