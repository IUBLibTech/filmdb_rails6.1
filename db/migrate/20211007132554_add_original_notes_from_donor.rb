class AddOriginalNotesFromDonor < ActiveRecord::Migration[4.2]
  def change
    add_column :equipment_technologies, :original_notes_from_donor, :text
  end
end
