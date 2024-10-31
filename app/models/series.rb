class Series < ApplicationRecord
  has_many :titles, autosave: true
  belongs_to :creator, class_name: "User", foreign_key: "created_by_id", autosave: true, optional: true
  belongs_to :modifier, class_name: "User", foreign_key: "modified_by_id", autosave: true, optional: true

  # returns an array of distinct series titles that are associated with the spreadsheet but also not (series created
  # in other spreadsheets or created manually that have the same title text as the records in the spreadsheet)
  scope :series_titles_not_in_spreadsheet, -> (ss_id) {
    series_title_array = Series.series_titles_in_spreadsheet(ss_id)
    Series.where(title: series_title_array).where('spreadsheet_id IS NULL OR spreadsheet_id != ?',ss_id).pluck(:title)
  }
  # returns an array of distinct series titles that appear in the specified spreadsheet
  scope :series_titles_in_spreadsheet, -> (ss_id) {
    Series.select(:title).where(spreadsheet_id: ss_id).distinct.pluck(:title)
  }

  # returns a map of Series title to the count of series records created by the spreadsheet ingest
  scope :series_title_count_in_spreadsheet, -> (ss_id) {
    Series.where(spreadsheet_id: ss_id).group(:title).count
  }

  # returns a map of those series titles that appear in the spreadsheet but also appear outside the spreadsheet (created in
  # another spreadsheet or manually) mapped to the count of those titles
  scope :series_title_count_not_in_spreadsheet, -> (ss_id) {
    series_title_array = Series.series_titles_in_spreadsheet(ss_id)
    Series.where(title: series_title_array).where('spreadsheet_id IS NULL OR spreadsheet_id != ?', ss_id).group(:title). count
  }

  # returns all series with matching series_title that appear in the specified spreadsheet
  scope :series_in_spreadsheet, -> (series_title, ss_id) {
    Series.where(title: series_title).where(spreadsheet_id: ss_id)
  }

  # returns all series objects with series_title but were created in other spreadsheets or created manually
  scope :series_not_in_spreadsheet, -> (series_title, ss_id) {
    Series.where(title: series_title).where('spreadsheet_id IS NULL OR spreadsheet_id != ?', ss_id)
  }

  scope :series_without_titles, -> {
    Series.find_by_sql("select * from series where series.id not in (select distinct(series_id) from titles where series_id is not null)")
  }
  scope :series_without_titles_count, -> {
    res = connection.execute("select count(distinct(id)) from series where series.id not in (select distinct(series_id) from titles where series_id is not null)")
    res.first.nil? ? 0 : res.first[0]
  }

  scope :accompanying_documentations, -> (series) {
    AccompanyingDocumentation.where(series_id: series.id)
  }

  def accompanying_documentations
    AccompanyingDocumentation.where(series_id: self.id)
  end

end
