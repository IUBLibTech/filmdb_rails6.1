# noinspection ALL
class CsvParser
	include DateHelper
  include PhysicalObjectsHelper
  include ParserHelper
  require 'csv'
  require 'film_parser'
  require 'video_parser'
  require 'manual_roll_back_error'

  # special logger for parsing spreadsheets
  def self.logger
    @@logger ||= Logger.new("#{Rails.root}/log/spreadsheet_submission_logger.log")
  end
  @@mutex = Mutex.new

  def initialize(filepath, spreadsheet, spreadsheet_submission)
    @filepath = filepath.tempfile.path unless filepath.nil?
    @spreadsheet = spreadsheet
    @spreadsheet_submission = spreadsheet_submission
  end

  def column_headers
    PO_HEADERS
  end

  def parse_csv
    begin
      @csv = CSV.read(@filepath, headers: false)
    rescue
      @opened_file = File.open(@filepath, "r:ISO-8859-1:UTF-8")
      @csv = CSV.parse(@opened_file, headers: false)
    ensure
      @opened_file.close unless @opened_file.nil?
    end

    # first need to detemrine the Medium of physical objects being parsed
    medium = parse_spreadsheet_medium
    if medium.downcase == Film.to_s.downcase
      FilmParser.new(@csv, @spreadsheet, @spreadsheet_submission).parse_csv
    elsif medium.downcase == Video.to_s.downcase
      VideoParser.new(@csv, @spreadsheet, @spreadsheet_submission).parse_csv
    elsif medium == 'Recorded Sound'
      RecordedSoundParser.new(@csv, @spreadsheet, @spreadsheet_submission).parse_csv
    else
      raise "Cannot ingest spreadsheet. Unsupported Medium: #{medium}"
    end
  end

  private
  def parse_spreadsheet_medium
    headers = @csv[0]
    medium_index = -1
    @csv[0].each_with_index do |h, i|
      if h == 'Medium'
        medium_index = i
        break
      end
    end
    @csv[1][medium_index]
  end
end