class UpdateReturnedReelsWithFilmdbUser < ActiveRecord::Migration[4.2]
  def up
    filmdb_U = User.where(username: 'filmdb').first
    raise "Cannot find Filmdb user... previous migration should have created this" if filmdb_U.nil?
    WorkflowStatus.where(status_name: WorkflowStatus::PULLABLE_STORAGE, created_by: nil).update_all(created_by: filmdb_U)
  end

  def down
    # can undo this...
  end
end
