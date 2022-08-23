class RemoveMiscCollections < ActiveRecord::Migration[4.2]
  def change
    Collection.where(name: 'Misc [not in collection]').delete_all
  end
end
