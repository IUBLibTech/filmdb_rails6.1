class IncreasePodPushesResponseSize < ActiveRecord::Migration[4.2]
  def up
    change_column :pod_pushes, :response, :text, :limit => 4294967295
  end
  def down

  end
end
