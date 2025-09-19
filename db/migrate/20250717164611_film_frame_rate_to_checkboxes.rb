class FilmFrameRateToCheckboxes < ActiveRecord::Migration[8.0]
  def up
    add_column :films, :fps_12, :boolean unless column_exists? :films, :fps_12
    add_column :films, :fps_16, :boolean unless column_exists? :films, :fps_16
    add_column :films, :fps_18, :boolean unless column_exists? :films, :fps_18
    add_column :films, :fps_24, :boolean unless column_exists? :films, :fps_24
    add_column :films, :fps_25, :boolean unless column_exists? :films, :fps_25
    films = Film.all
    films.each_with_index  do |f, index|
      puts "#{index + 1} of #{films.length}"
      save = true
      case f.frame_rate
      when "12 fps"
        f.fps_12 = true
      when "16 fps"
        f.fps_16 = true
      when "18 fps"
        f.fps_18 = true
      when "24 fps"
        f.fps_24 = true
      when "25 fps"
        f.fps_25 = true
      else
        save = false
      end
      f.save! if save
    end
  end

  def down
    # only need to drop the columns as the original frame_rate variable still exists as it did at the time of this migration
    remove_column :films, :fps_12, :boolean
    remove_column :films, :fps_16, :boolean
    remove_column :films, :fps_18, :boolean
    remove_column :films, :fps_24, :boolean
    remove_column :films, :fps_25, :boolean
  end
end
