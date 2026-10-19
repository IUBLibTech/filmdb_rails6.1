class RetitleOrphanedComponentGroups < ActiveRecord::Migration[8.0]
  def up
    OrphanedComponentGroupCleaner.new.retitle_cgs
  end

  def down
    # there is no spoon
  end
end
