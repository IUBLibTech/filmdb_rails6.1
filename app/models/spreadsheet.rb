class Spreadsheet < ApplicationRecord
  include DateHelper
  require 'csv'

	has_many :physical_objects
	has_many :spreadsheet_submissions, dependent: :delete_all
  has_many :titles
  has_many :series
	has_many :created_users, class_name: "User", foreign_key: "created_in_spreadsheet"

  scope :distinct_series, -> (spreadsheet_id) {
    Series.select(:title).where(spreadsheet_id: spreadsheet_id).distinct.order(:title).pluck(:title)
  }

  scope :distinct_titles, -> (spreadsheet_id) {
    Title.select(:title_text).where(spreadsheet_id: spreadsheet_id).distinct.order(:title_text).pluck(:title_text)
  }

	def current_submission
		spreadsheet_submissions.order(:created_at).last
  end

  # Utility that reads a CSV file
  def self.parse_existing(filepath)
    begin
      @csv = CSV.read(filepath, headers: false)
    rescue
      opened_file = File.open(filepath, "r:ISO-8859-1:UTF-8")
      @csv = CSV.parse(opened_file, headers: false)
    end
    iubc_i = @csv[0].index('IU Barcode')
    new_records = []
    existing_records = []
    @csv.each_with_index do |row, i|
      unless i == 0
        puts "Parsing row #{i} of #{@csv.size - 1}"
        if (PhysicalObject.where(iu_barcode: row[iubc_i]).empty? && PhysicalObjectOldBarcode.where(iu_barcode: row[iubc_i]).empty?)
          new_records << row
        else
          existing_records << row
        end
      end
    end
    file = "#{Rails.root}/tmp/to_ingest.csv"
    CSV.open(file, 'w') do |csv|
      csv << @csv[0]
      new_records.each do |row|
        csv << row
      end
    end
    file = "#{Rails.root}/tmp/already_ingested.csv"
    CSV.open(file, 'w') do |csv|
      csv << @csv[0]
      existing_records.each do |row|
        csv << row
      end
    end
  end



end
