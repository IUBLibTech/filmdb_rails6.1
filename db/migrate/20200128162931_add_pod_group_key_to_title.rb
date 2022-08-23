class AddPodGroupKeyToTitle < ActiveRecord::Migration[4.2]
  def change
    # the only place this should be used is in service calls to POD, don't store as an integer because we want to be
    # able to test if blank?
    add_column :titles, :pod_group_key_identifier, :string
  end
end
