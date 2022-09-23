class AddJsonToPullRequest < ActiveRecord::Migration[6.1]
  def change
    add_column :pull_requests, :caia_soft, :boolean
    add_column :pull_requests, :json_payload, :text, limit: 65536
    add_column :pull_requests, :caia_soft_upload_success, :boolean
    add_column :pull_requests, :caia_soft_response, :text, limit: 65536
  end
end
