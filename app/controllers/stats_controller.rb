class StatsController < ApplicationController

	before_action :set_filters
	before_action :set_counts

	def index
	end

	def filter_index
		if (@startTime && !@endTime) || (@endTime && !@startTime)
			flash[:notice] = 'You only specified a single date, not a range'
		end
		render 'index'
	end

	def empty_titles

	end

	def empty_series

	end

	def ajax_medium_stats
		if params[:medium] == 'Film'
			@generations = generations(Film)
			@gauges = Film.joins("INNER JOIN physical_objects ON physical_objects.actable_id = films.id").where(po_sql_where).where("gauge is not null AND gauge != ''").group(:gauge).count
			@can_sizes = can_sizes(Film)
			@bases = bases(Film)
			@sounds = sounds(Film)
			@colors = colors(Film)
			@conditions = PhysicalObject.where(po_sql_where).where(medium: 'Film').where("condition_rating is not null and condition_rating != ''").group(:condition_rating).count
			render partial: 'film_metadata_stats'
		elsif params[:medium] == 'Video'
			@generations = generations(Video)
			@gauges = Video.joins("INNER JOIN physical_objects ON physical_objects.actable_id = videos.id").where(po_sql_where).where("gauge is not null AND gauge != ''").group(:gauge).count
			@bases = bases(Video)
			@sounds = sounds(Video)
			@colors = colors(Video)
			@conditions = PhysicalObject.where(po_sql_where).where(medium: 'Video').where("condition_rating is not null and condition_rating != ''").group(:condition_rating).count
			render partial: 'video_metadata_stats'
		elsif params[:medium] == 'Recorded Sound'
			@generations = generations(RecordedSound)
			@gauges = RecordedSound.joins("INNER JOIN physical_objects ON physical_objects.actable_id = recorded_sounds.id").where(po_sql_where).where("gauge is not null and gauge !=''").group(:gauge).count
			@bases = bases(RecordedSound)
			@sounds = [] # not applicable to recorded sound
			@colors = [] # not applicable to recorded sound
			@conditions = PhysicalObject.where(po_sql_where).where(medium: 'Recorded Sound').where("condition_rating is not null and condition_rating != ''").group(:condition_rating).count
			render partial: 'recorded_sound_metadata_stats'
		else
			render text: "Unsupported medium: #{params[:medium]}", status: 400
		end
	end


	private
	def set_counts
		if any_filters?
			#if unit or collection are specified we have to go from physical object to title/series since
			# the associations to unit/collect are through physical object and not title.
			@title_count = Title.find_by_sql(title_count_sql).size
			@digitized_count = PhysicalObject.where(po_sql_where).where(digitized: true).size
			@title_cat_count = Title.find_by_sql(title_cat_count_sql).size
			@physical_object_count = PhysicalObject.where(po_sql_where).size
			#@empty_title_count = "N/A"
			#@empty_series_count = "N/A"
			@series_count = Series.find_by_sql(series_count_sql).size
		else
			@title_count = Title.all.size
			@digitized_count = PhysicalObject.where(digitized: true).size
			@title_cat_count = Title.where(fully_cataloged: true).size
			#@empty_title_count = Title.count_titles_without_physical_objects
			@series_count = Series.all.size
			#@empty_series_count = Series.series_without_titles_count
			@physical_object_count = PhysicalObject.all.size
		end

		@medium_count = PhysicalObject.where(po_sql_where).group(:medium).count
	end

	def any_filters?
		@unit || @collection || @startTime || @endTime
	end

	def set_filters
		unless params[:unit].blank? || params[:unit] == 0
			@unit = Unit.find(params[:unit])
		end
		unless params[:collection_id].blank? || params[:collection_id] == 0
			@collection = Collection.find(params[:collection_id])
		end
		unless params[:start].blank? || params[:start] == 0
			begin
				@startTime = DateTime.strptime(params[:start], "%m/%d/%Y")
			rescue
			end
			begin
				@endTime = DateTime.strptime(params[:end], "%m/%d/%Y") + 23.hours + 59.minutes + 59.seconds
			rescue
			end
		end
		@filter_msg = (@collection ? "[#{@collection.unit.abbreviation} - #{@collection.name}]" : (@unit ? "[#{@unit.abbreviation}]" : "[Global]"))
	end

	def po_sql_where
		sql = @unit ? " unit_id = #{@unit.id}" : ""
		sql += @collection ? (sql.length > 0 ? " AND " : "")+"collection_id = #{@collection.id}" : ""
		sql += @startTime ? (sql.length > 0 ? " AND " : "")+"physical_objects.created_at >= '#{@startTime}' AND physical_objects.created_at <= '#{@endTime}' " : ""
		sql
	end

	def title_count_sql
		"select distinct(titles.id) from physical_objects, titles, physical_object_titles "+
				"where #{po_sql_where} and physical_objects.id = physical_object_titles.physical_object_id and physical_object_titles.title_id = titles.id"
	end

	def po_digit_count
		"select count(*) from physical_objects where #{po_sql_where} AND digitized = true"
	end

	def title_cat_count_sql
		"select distinct(titles.id) from physical_objects, titles, physical_object_titles "+
				"where #{po_sql_where} AND physical_objects.id = physical_object_titles.physical_object_id AND "+
				"physical_object_titles.title_id = titles.id AND titles.fully_cataloged = true"
	end

	def series_count_sql
		"SELECT distinct(series.id) FROM physical_objects, physical_object_titles, titles, series "+
			"WHERE #{po_sql_where} AND physical_objects.id = physical_object_titles.physical_object_id AND titles.id = physical_object_titles.title_id AND titles.series_id = series.id"
	end

	def generations(cl)
		gens = Hash.new
		cl::GENERATION_FIELDS.each do |gf|
			count =  cl.where(gf => true).joins("INNER JOIN physical_objects ON physical_objects.actable_id = #{cl.to_s.downcase.pluralize}.id").where(po_sql_where).size
			gens[cl::GENERATION_FIELDS_HUMANIZED[gf]] = count unless count == 0
		end
		gens
	end

	def bases(cl)
		b = Hash.new
		if cl == Film
			Film::BASE_FIELDS.each do |bf|
				count = Film.where(bf => true).joins("INNER JOIN physical_objects ON physical_objects.actable_id = #{cl.to_s.downcase.pluralize}.id").where(po_sql_where).size
				b[Film::BASE_FIELDS_HUMANIZED[bf]] = count unless count == 0
			end
		elsif cl == Video
			count = Video.joins("INNER JOIN physical_objects ON physical_objects.actable_id = videos.id").where(po_sql_where).group(:base).size
			b = count
			b["Not Specifiec"] = b.delete("") unless b[""].nil?
		end
		b
	end

	def can_sizes(cl)
		Film.where("can_size is not null and can_size != ''").group(:can_size).count
	end

	def sounds(cl)
		sounds = Hash.new
		cl::SOUND_FORMAT_FIELDS.each do |sf|
			count = cl.where(sf => true).joins("INNER JOIN physical_objects ON physical_objects.actable_id = #{cl.to_s.downcase.pluralize}.id").where(po_sql_where).size
			sounds[cl::SOUND_FORMAT_FIELDS_HUMANIZED[sf]] = count unless count == 0
		end
		sounds
	end

	def colors(cl)
		colors = Hash.new
		cl::COLOR_FIELDS.each do |cf|
			count = cl.where(cf => true).joins("INNER JOIN physical_objects ON physical_objects.actable_id = #{cl.to_s.downcase.pluralize}.id").where(po_sql_where).size
			colors[cl::COLOR_FIELDS_HUMANIZED[cf]] = count unless count == 0
		end
		colors
	end
end
