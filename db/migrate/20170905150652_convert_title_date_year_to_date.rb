include DateHelper

class ConvertTitleDateYearToDate < ActiveRecord::Migration[4.2]
  def change
	  rename_column :title_dates, :date, :date_text
	  add_column :title_dates, :start_date, :date
	  add_column :title_dates, :month_present, :boolean
	  add_column :title_dates, :day_present, :boolean
	  add_column :title_dates, :extra_text, :boolean
	  TitleDate.all.each do |td|
		  text = td.date_text
		  map = convert_to_date(text)
		  if map
			  td.update(start_date: map[:date], month_present: map[:month], day_present: map[:day], extra_text: map[:extra])
		  end
	  end
  end
end
