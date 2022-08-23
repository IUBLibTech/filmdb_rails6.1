class CreatePullRequests < ActiveRecord::Migration[4.2]
  def change
    create_table :pull_requests do |t|
      t.integer :created_by_id, limit: 8
			t.string :filename
      t.text :file_contents, limit: 16777215 #MySQL MEDIUMTEXT
      t.timestamps
    end
  end
end
