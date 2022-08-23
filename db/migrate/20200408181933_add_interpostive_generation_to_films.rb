class AddInterpostiveGenerationToFilms < ActiveRecord::Migration[4.2]
  def change
    add_column :films, :generation_interpositive, :boolean
  end
end
