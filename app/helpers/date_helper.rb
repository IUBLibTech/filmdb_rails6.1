module DateHelper

	@@year_rgx = /^\[{0,1}([0-9]{3,3}\?{1,1}|[0-9]{4,4})\]{0,1}$/
	@@year_only_rgx = /^\[{0,1}([0-9]{4,4})\]{0,1}$/
	@@year_month_rgx = /^\[{0,1}([0-9]{4})\/([0-9]{1,2})\]{0,1}$/
	@@year_month_day_rgx = /^\[{0,1}([0-9]{4})\/([0-9]{1,2})\/([0-9]{1,2})\]{0,1}$/

	# Tests if the specified string is a 4 digit value - does not test if the year is 'meaningful': '0000' would return the MatchData
	def year_only?(date)
		date.length == 4 && @@year_rgx.match(date)
	end

	def year_month?(date)
		@@year_month_rgx.match(date)
	end

	def year_month_day?(date)
		@@year_month_day_rgx.match(date)
	end

	# returns a set containing:
	# :start_date a map formatted like self.convert_month_day_date
	# :end_date an optional map if the specified date is a range or a decade notation ([196?])
	def self.convert_dates(date)
		# remove white space and replace all en/em dashes (thank you MS Excel...) with hyphens
		dates = date.gsub(/\s+/,"").gsub(/[\xE2\x80\x94\xE2\x80\x93]/,'-').split('-')
		set = {}
		if dates.size == 1 && !dates[0].blank?
			match = @@year_rgx.match(dates[0])
			if match.nil?
				set[:start_date] = convert_month_day_date(dates[0])
			else
				year = match[1]
				if year[-1] == '?'
					set[:start_date] = convert_year_date(match[0].gsub('?', '0'))
					set[:end_date] = convert_year_date(match[0].gsub('?', '9'), true)
				else
					set[:start_date] = convert_year_date(match[1])
				end
			end
			set[:start_date][:approximation] = (dates[0][0] == '[' && dates[0][-1] == ']')
		elsif dates.size == 2 && (!dates[0].blank? && !dates[1].blank?)
			match = @@year_only_rgx.match(dates[0])
			if match.nil?
				set[:start_date] = convert_month_day_date(dates[0])
			else
				set[:start_date] = convert_year_date(dates[0])
			end
			match = @@year_only_rgx.match(dates[1])
			if match.nil?
				set[:end_date] = convert_month_day_date(dates[1], true)
			else
				set[:end_date] = convert_year_date(dates[1], true)
			end
			# both start and end must be present for the date range to be properly formatted, return an empty set if either is nil
			if set[:start_date].nil? || set[:end_date].nil?
				set = {}
			end
			set[:start_date][:approximation] = (dates[0][0] == '[' && dates[0][-1] == ']')
			set[:end_date][:approximation] = (dates[1][0] == '[' && dates[1][-1] == ']')
		else
			# do what?
		end
		set
	end

	def self.approximation?(date)
		date[0] == '[' && date[-1] == ']'
	end

	# converts a non-decade-year-only-date ([1968] - NOT [196?]) to its map representation of date, month, day, approximation.
	# end_date specifies whether the date should be treated as the end date in a range (getting Dec 31 as the month day value)
	def self.convert_year_date(date, end_date=false)
		match = @@year_only_rgx.match(date)
		if match.nil?
			nil
		else
			year = match[1]
			{
				date: Date.new(year.to_i, (end_date ? 12 : 1), (end_date ? 31 : 1)),
				month: false,
				day: false,
				approximation: approximation?(match[0])
			}
		end
	end

	# takes a single (non-year-only date string - test that first before calling this) and converts it into a map containing
	# :date contains a valid Date object
	# :month is a boolean value specifying whether the month was present in the date string
	# :day a boolean value specifying whether the day was present in the date string
	# :approximation a boolean denoting whether the date was surrounded by square brackets - meaning it is an approximate date: [1965/10]
	def self.convert_month_day_date(date, end_date=false)
		match = @@year_month_day_rgx.match(date)
		if match.nil?
			match = @@year_month_rgx.match(date)
		end
		if match.nil?
			nil
		else
			begin
				year = match[1].to_i
				month = match[2]&.to_i
				day = match[3]&.to_i
				d = Date.new(year, (month.nil? ? (end_date ? 12 : 1) : month), (day.nil? ? (end_date ? 31 : 1) : day))
				map = {}
				map[:date] = d
				map[:month] = !match[2].nil?
				map[:day] = !match[3].nil?
				map[:approximation] = approximation?(match[0])
				map
			rescue
				nil
			end
		end
	end

	# CURRENTLY ONLY USED BY A MIGRATION FILE - DO NOT USE FOR ANYTHING!!!!
	# returns nil if there was no pattern matching against the specified string, or a map of the following:
	# :date contains a valid Date object
	# :month is a boolean value specifying whether the month was present in the date string
	# :day a boolean value specifying whether the day was present in the date string
	# :extra is a boolean value specifying whether there was additional text beyond the pattern matched
	def convert_to_date(date)
		match = year_month_day?(date)
		if match.nil?
			match = year_month?(date)
			if match.nil?
				match = year_only?(date)
			end
		end
		if match.nil?
			nil
		else
			begin
				year = match[1].to_i
				month = match[2]&.to_i
				day = match[3]&.to_i
				d = day.nil? ? (month.nil? ? Date.new(year) : Date.new(year, month)) : Date.new(year, month, day)
				map = {}
				map[:date] = d
				map[:month] = !match[2].nil?
				map[:day] = !match[3].nil?
				map[:extra] = (match[0].length != date.length)
				map
			rescue
				nil
			end
		end
	end

	def date_to_s
		if is_decade?
			"[#{start_date.year.to_s[0...-1]}?]"
		else
			s_date = d_to_s(start_date, start_month_present, start_day_present, start_date_is_approximation)
			e_date = d_to_s(end_date, end_date_month_present, end_date_day_present, end_date_is_approximation)
			"#{s_date}#{e_date.nil? ? '' : " - #{e_date}"}"
		end
	end

	def is_decade?
		start_date_is_approximation && !start_month_present &&
			!end_date.nil? && end_date_is_approximation && !end_date_month_present &&
			((end_date.year - start_date.year == 9) && (end_date.year % 10 == 9) && (start_date.year % 10 ==0))
	end

	private
	def d_to_s(date, month_present, day_present, is_approximate)
		if date.nil?
			nil
		else
			d = ""
			if day_present
				d = date.strftime("%Y/%m/%d")
			elsif month_present
				d = date.strftime("%Y/%m")
			else
				d = date.strftime("%Y")
			end
			is_approximate ? "[#{d}]" : d
		end
	end

	def parse_date_text
		date_set = DateHelper.convert_dates(self.date_text)
		if date_set[:start_date].nil?
			raise "Unable to parse date: #{date_text}"
		end
		self.start_date = date_set[:start_date][:date]
		self.start_month_present = date_set[:start_date][:month]
		self.start_day_present = date_set[:start_date][:day]
		self.start_date_is_approximation = date_set[:start_date][:approximation]
		unless date_set[:end_date].nil?
			self.end_date = date_set[:end_date][:date]
			self.end_date_month_present = date_set[:end_date][:month]
			self.end_date_day_present = date_set[:end_date][:day]
			self.end_date_is_approximation = date_set[:end_date][:approximation]
		end
	end


end
