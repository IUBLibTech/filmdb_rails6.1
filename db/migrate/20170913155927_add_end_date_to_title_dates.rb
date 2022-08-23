class AddEndDateToTitleDates < ActiveRecord::Migration[4.2]
  def change
    rename_column :title_dates, :month_present, :start_month_present
    rename_column :title_dates, :day_present, :start_day_present
    add_column :title_dates, :start_date_is_approximation, :boolean
    add_column :title_dates, :end_date, :date
    add_column :title_dates, :end_date_month_present, :boolean
    add_column :title_dates, :end_date_day_present, :boolean
    add_column :title_dates, :end_date_is_approximation, :boolean
  end
end
