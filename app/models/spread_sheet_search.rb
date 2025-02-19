class SpreadSheetSearch < ApplicationRecord
  require "axlsx"
  #include SpreadsheetSearcher
  belongs_to :user
  belongs_to :collection, optional: true

  # we can't know what percent total job runtime a query has until after the job is complete. This value is used to 'edtimate'
  # where we are in the job after the query completes. Eventually, we'll look at statistics to find a better estimate for
  # the average of query runtimes
  ARBITRARY_QUERY_PERCENT = 10

  def logger
    @@my_logger ||= Logger.new("#{Rails.root}/log/spreadsheet_job_log.log")
  end

  def username
    user.username
  end

  def collection_name
    collection&.name
  end

  def in_progress?
    completed.nil? && percent_complete < 100
  end

  def filename
    file_location.gsub('tmp/', '')
  end

  def create
    begin
      # the query portion of the download begins first with logging and ActiveModel update of the saved record
      @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      logger.info "Creating new SpreadSheetSearch for #{user.username} with id: #{id}"
      q = run_query
      @end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed = @end_time - @start_time
      logger.info "Query for spreadsheet id: #{id} took #{elapsed} seconds to complete"
      # arbitrarily choose "10%" completion after the query runs to indicate some work has been done
      update(query_runtime: elapsed, percent_complete: 10)

      # now the looooong part - generating the spreadsheet
      @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      logger.info "Starting spreadsheet generation for id: #{id}"
      ss = generate_spreadsheet(q)
      # save the file
      file_location = "tmp/#{username}_#{id.to_s.rjust(4, "0")}.xlsx"
      if save_spreadsheet_to_file(ss, file_location)
        @end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        update(completed: true, percent_complete: 100, file_location: file_location, spreadsheet_runtime: @end_time - @start_time)
        logger.info "Complete spreadsheet for #{id}"
      else
        raise "Failed to save the spreadsheet file to #{file_location}"
      end
    rescue => e
      # if we don't catch -ALL- exceptions here, the delayed_job will fail and attempt to re-run at a later time. We also
      # want the stack trace stored with the SpreadSheetSearch object along with doing some book keeping to indicate the
      # spreadsheet generation failed
      error_msg = e.message
      error_msg << e.backtrace.join("\n")
      logger.info error_msg
      update(completed: false, error_message: error_msg)
    end
  end
  handle_asynchronously :create # this tells the delayed_job gem to run this in a background process

  def run_query
    if title_text.blank?
      titles = Title.all
    else
      match = title_text.match(Title::QUOTED)
      if match
        titles = Title.where("title_text REGEXP ?", "\\b"+match[1]+"\\b")
      else
        titles = Title.where("title_text like '%#{title_text}%'")
      end
    end
    titles = titles.joins(:physical_objects).includes(:physical_objects)
    if collection_id != 0
      titles = titles.where("physical_objects.collection_id = ?", collection_id) unless collection_id == 0
    end
    if medium_filter == Title::FILM_MEDIUMS
      titles = titles.where("(physical_objects.medium = ?)", "Film")
    elsif medium_filter == Title::VIDEO_MEDIUMS
      titles = titles.where("(physical_objects.medium = ?)", "Video")
    elsif medium_filter == Title::FILM_MEDIUMS + Title::VIDEO_MEDIUMS
      titles = titles.where("(physical_objects.medium = ? OR physical_objects.medium = ?)", "Film", "Video")
    elsif medium_filter == Title::RECORDED_SOUND_MEDIUMS
      titles = titles.where("(physical_objects.medium = ?)", "Recorded Sound")
    elsif medium_filter == Title::FILM_MEDIUMS + Title::RECORDED_SOUND_MEDIUMS
      titles = titles.where("(physical_objects.medium = ? OR physical_objects.medium = ? )", "Film", "RecordedSound")
    elsif medium_filter == Title::VIDEO_MEDIUMS + Title::RECORDED_SOUND_MEDIUMS
      titles = titles.where("(physical_objects.medium = ? OR physical_objects.medium = ? )", "Video", "RecordedSound")
    end
    unless digitized_status == 'all'
      if digitized_status == "not_digitized"
        titles = titles.where("titles.stream_url is null OR titles.stream_url = ''")
      elsif digitized_status == "digitized"
        titles = titles.where("titles.stream_url is not null AND titles.stream_url != ''")
      end
    end
    titles = titles.where("titles.summary LIKE ?", "%#{summary_text}%") unless summary_text.blank?
    titles = titles.where("titles.subject LIKE ?", "%#{subject_text}%") unless subject_text.blank?

    titles = titles.joins(:series).includes(:series).where("series.title LIKE ?", "%#{series_name}%") unless series_name.blank?

    unless date_text.blank?
      dates = date_text.gsub(' ', '').split('-')
      if dates.size == 1
        d1 = EDTF.parse(dates[0])
        titles = titles.joins(:title_dates).includes(:title_dates).where(
          "title_dates.end_date is null AND year(title_dates.start_date) = ? OR "+
            "(title_dates.start_date <= ? AND title_dates.end_date >= ?)", d1,d1,d1)
      else
        d1 = EDTF.parse(dates[0])
        d2 = EDTF.parse(dates[1])
        titles = titles.joins(:title_dates).includes(:title_dates).where(
          "(title_dates.start_date BETWEEN ? AND ?) "+
            "OR (title_dates.end_date BETWEEN ? AND ?) "+
            "OR (title_dates.start_date < ? AND title_dates.end_date > ?)",
          d1, d2, d1, d2, d1, d2
        )
      end
    end
    titles = titles.joins(:title_publishers).includes(:title_publishers).where("title_publishers.name like ?", "%#{publisher_text}%") unless publisher_text.blank?
    titles = titles.joins(:title_creators).includes(:title_creators).where("title_creators.name like ?", "%#{creator_text}%") unless creator_text.blank?
    titles = titles.joins(:title_genres).includes(:title_genres).where("title_genres.genre = ?", genre) unless genre.blank?
    titles = titles.joins(:title_forms).includes(:title_forms).where("title_forms.form = ?", form) unless form.blank?
    titles = titles.joins(:title_locations).includes(:title_locations).where("title_locations.location like ?", "%#{location_text}%") unless location_text.blank?

    titles
  end

  def filter_text
    text = "All"
    unless medium_filter.blank? || medium_filter == 0
      text = ""
      text += "Film" if medium_filter & Title::FILM_MEDIUMS == Title::FILM_MEDIUMS
      if medium_filter & Title::VIDEO_MEDIUMS == Title::VIDEO_MEDIUMS
        text += text.size > 0 ? ", Video" : "Video"
      end
      if medium_filter & Title::RECORDED_SOUND_MEDIUMS == Title::RECORDED_SOUND_MEDIUMS
        text += text.size > 0 ? ", Recorded Sound" : "Recorded Sound"
      end
    end
    text
  end

  def generate_spreadsheet(titles)
    x = Axlsx::Package.new
    wb = x.workbook
    if (medium_filter & Title::FILM_MEDIUMS == Title::FILM_MEDIUMS) || medium_filter == 0
      films = wb.add_worksheet(name: "Films")
      Film.write_xlsx_header_row( films)
    end
    if (medium_filter & Title::VIDEO_MEDIUMS == Title::VIDEO_MEDIUMS) || medium_filter == 0
      videos = wb.add_worksheet(name: "Videos")
      Video.write_xlsx_header_row( videos )
    end
    if (medium_filter & Title::RECORDED_SOUND_MEDIUMS == Title::RECORDED_SOUND_MEDIUMS) || medium_filter == 0
      recorded_sounds = wb.add_worksheet(name: "Recorded Sounds")
      RecordedSound.write_xlsx_header_row( recorded_sounds )
    end
    total = titles.size.to_f
    titles.each_with_index do |t, i|
      # we want to avoid excessive writes to the database while updating the completion status of the job
      # so only write when -percent_complete- state jumps forward by 5%. Remember, percent_complete is the
      # total JOB completion state: at this point in code, the time taken to run the query AND where we are in spreadsheet
      # generation. To get that value we have to do some ugly math...
      #
      # We defined a guesstimated fixed percentage of a job's runtime for the query portion (because that can't be known
      # ahead of time): ARBITRARY_QUERY_RUNTIME. The percentage of time a job takes on SS generation is 100 (percent)
      # minus ARBITRARY_QUERY_RUNTIME. To get total percent completion of the JOB:
      # ARBITRARY_QUERY_RUNTIME + ((100 - ARBITRARY_QUERY_RUNTIME) * <what percentage of titles we've process so far>)
      title_percent = i / total
      total_percent = ARBITRARY_QUERY_PERCENT + ((100 - ARBITRARY_QUERY_PERCENT) * title_percent)
      if total_percent >= percent_complete + 5
        update(percent_complete: total_percent.to_i)
      end
      t.physical_objects.each_with_index do |po, i|
        if po.specific.medium == "Film"
          @worksheet = films
        elsif po.specific.medium == "Video"
          @worksheet = videos
        elsif po.specific.medium == "Recorded Sound"
          @worksheet = recorded_sounds
        else
          next
        end
        po.specific.write_xlsx_row(t, @worksheet)
      end
    end
    x
  end

  def save_spreadsheet_to_file(ss, filename)
    ss.serialize(filename)
  end





end
