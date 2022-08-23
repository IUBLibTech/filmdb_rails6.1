class IncreaseTitleTextFieldSize < ActiveRecord::Migration[4.2]
  def up
    change_column :titles, :title_text, :string, limit: 1024
  end

	def down
		change_column :titles, :title_text, :string, limit: 256
	end
end
