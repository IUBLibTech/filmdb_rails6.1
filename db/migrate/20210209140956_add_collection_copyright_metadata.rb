class AddCollectionCopyrightMetadata < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :accessible, :boolean
    add_column :collections, :accessible_notes, :text
    # README!!! consult the Collection model for documentation on how these work
    add_column :collections, :current_ownership_and_control, :integer
    add_column :collections, :transfer_of_ownership, :integer
  end
end
