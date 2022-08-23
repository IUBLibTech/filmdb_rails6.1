class AddCompilationToTitle < ActiveRecord::Migration[4.2]
  def change
    add_column :titles, :compilation, :text
  end
end
