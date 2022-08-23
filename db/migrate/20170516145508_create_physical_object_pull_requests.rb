class CreatePhysicalObjectPullRequests < ActiveRecord::Migration[4.2]
  def change
    create_table :physical_object_pull_requests do |t|
      t.integer :physical_object_id, limit: 8
      t.integer :pull_request_id, limit: 8
      t.timestamps
    end
  end
end
