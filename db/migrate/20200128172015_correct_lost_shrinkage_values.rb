class CorrectLostShrinkageValues < ActiveRecord::Migration[4.2]
  def up
    path = "#{Rails.root}/tmp/shrinkage_update.csv"
    begin
      return unless File.exists? path
      @csv = CSV.read(path, headers: false)
    rescue
      @opened_file = File.open(path, "r:ISO-8859-1:UTF-8")
      @csv = CSV.parse(@opened_file, headers: false)
    end
    Film.transaction do
      change_column :films, :shrinkage, :float
      @csv.each_with_index do |row, i|
        next if i == 0
        puts "Row: #{i} of #{@csv.size}"
        film = PhysicalObject.where(id: row[0].to_i).first&.specific
        film.update(shrinkage: row[1].to_f) unless film.nil?
      end
    end
  end

  def down
    change_column :films, :shrinkage, :integer
  end
end
