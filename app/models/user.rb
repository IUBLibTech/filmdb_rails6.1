class User < ApplicationRecord

	validates :username, presence: true, uniqueness: true
	belongs_to :created_in_sheet, class_name: "Spreadsheet", foreign_key: "created_in_spreadsheet", optional: true

	WORK_LOCATION_ALF = "ALF"
	WORK_LOCATION_WELLS = 'Wells 052'

	scope :active_user_emails, -> {
		User.where("active == true AND username != 'jaalbrec'").pluck(:email_address)
	}

	def self.authenticate(username)
		return false if username.nil? || username.blank?
		return false if !active_user?(username)
		return true if valid_usernames.include? username
		return false
	end

	def self.valid_usernames
		return User.all.map { |user| user.username }
	end

	def self.active_user?(username)
		u = User.where(username: username).first
		return !u.nil? && u.active?
	end

	def self.current_username=(user)
		Thread.current[:current_username] = user
	end

	def self.current_username
		user_string = Thread.current[:current_username].to_s
		user_string.blank? ? "UNAVAILABLE" : user_string
	end

	def self.current_user_object
		User.where(username: current_username).first
	end

	def self.active_user_emails
		User.where(active: true).pluck(:email_address).join(',')
	end

	def name
		first_name + ' ' + last_name
	end

	def worksite_timed_out?
		works_in_both_locations? && (updated_at + SessionsHelper::TIME_OUT < Time.now)
	end

	def worksite_set?
		!worksite.nil?
	end

	def current_worksite
		worksite_location
	end

	# This method converts a User::WORK_LOCATION_X into it's corresponding ComponentGroup::WORKFLOW_WELLS/ALF location
	def worksite_to_delivery_location
		if worksite_location == WORK_LOCATION_WELLS
			ComponentGroup::WORKFLOW_WELLS
		elsif worksite_location == WORK_LOCATION_ALF
			ComponentGroup::WORKFLOW_ALF
		else
			raise "Work location not set for User: #{self.username}"
		end
	end

end
