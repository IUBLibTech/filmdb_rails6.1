class PhysicalObject < ApplicationRecord
	actable

	include ActiveModel::Validations
	include PhysicalObjectsHelper

	#belongs_to :title
	belongs_to :spreadsheet, optional: true
	belongs_to :collection, autosave: true, optional: true
	belongs_to :unit, autosave: true
	belongs_to :inventorier, class_name: "User", foreign_key: "inventoried_by", autosave: true
	belongs_to :modifier, class_name: "User", foreign_key: "modified_by", autosave: true
  belongs_to :cage_shelf, optional: true
	belongs_to :active_component_group, class_name: 'ComponentGroup', foreign_key: 'component_group_id', autosave: true, optional: true

	# this must be optional because there is not workflow status at PO creation (inventorying)
	belongs_to :current_workflow_status, class_name: 'WorkflowStatus', foreign_key: 'current_workflow_status_id', autosave: true, optional: true

	has_many :physical_object_old_barcodes
  has_many :component_group_physical_objects, dependent: :delete_all
  has_many :component_groups, through: :component_group_physical_objects
  has_many :physical_object_titles, dependent: :delete_all
  has_many :titles, through: :physical_object_titles
	has_many :series, through: :titles
	has_many :physical_object_pull_requests
	has_many :pull_requests, through: :physical_object_pull_requests
	has_many :digiprovs
	has_many :physical_object_dates
	has_many :edge_codes

	validates :physical_object_titles, physical_object_titles: true
  validates :unit, presence: true
  #validates :media_type, presence: true
  validates :medium, presence: true
	# validates :gauge, presence: true

  has_many :boolean_conditions, autosave: true
  has_many :value_conditions, autosave: true
  has_many :languages, autosave: true
  has_many :physical_object_original_identifiers
	has_many :workflow_statuses, validate: false


  accepts_nested_attributes_for :boolean_conditions, allow_destroy: true
  accepts_nested_attributes_for :value_conditions, allow_destroy: true
  accepts_nested_attributes_for :languages, allow_destroy: true
  accepts_nested_attributes_for :physical_object_original_identifiers, allow_destroy: true
	accepts_nested_attributes_for :physical_object_dates, allow_destroy: true
	accepts_nested_attributes_for :edge_codes, allow_destroy: true

	attr_accessor :workflow
	attr_accessor :updated

	# handling this manually in physical_objects_controller#update
	#before_save :record_barcode_changes
	# def record_barcode_changes(po_id, old)
	# 	PhysicalObjectOldBarcode.new(physical_object_id: po_id, iu_barcode: old).save!
	# end

	# returns all physical whose workflow status matches any specified in *status - use WorkflowStatus status constants as values
	#
	# FIXME: PhysicalObject.joins(:current_workflow_status).where("workflow_statuses.status_name = '#{WorkflowStatus::QUEUED_FOR_PULL_REQUEST}'")
	scope :where_current_workflow_status_is, lambda { |offset, limit, digitized, *status|
		# status values are concatenated into an array so if you want to pass an array of values (constants stored in other classes for instance) the passed array is wrapped in
		# an enclosing array. flattening it allows an array to be passed and leaves any params passed the 'normal' way untouched
		status = status.flatten

		sql = "SELECT physical_objects.* "+
			"FROM ( SELECT workflow_statuses.physical_object_id "+
			  "FROM (	SELECT physical_object_id, max(created_at) AS status FROM workflow_statuses GROUP BY physical_object_id) AS x "+
			    "INNER JOIN workflow_statuses on (workflow_statuses.physical_object_id = x.physical_object_id AND x.status = workflow_statuses.created_at) "+
			    "WHERE workflow_statuses.status_name in (#{status.map(&:inspect).join(', ')})) as y INNER JOIN physical_objects on physical_object_id = physical_objects.id #{(offset.nil? || limit.nil?) ? '' : "LIMIT #{limit} OFFSET #{offset}"}"+
				(digitized ? " WHERE physical_objects.digitized = true" : "")
		PhysicalObject.find_by_sql(sql)
	}

	# returns all physical whose workflow status matches any specified in *status - use WorkflowStatus status constants as values
	scope :count_where_current_workflow_status_is, lambda { |digitized, *status|

		# status values are concatenated into an array so if you want to pass an array of values (constants stored in other classes for instance) the passed array is wrapped in
		# an enclosing array. flattening it allows an array to be passed and leaves any params passed the 'normal' way untouched
		status = status.flatten

		sql = "SELECT count(*) "+
			"FROM ( SELECT workflow_statuses.physical_object_id "+
			"FROM (	SELECT physical_object_id, max(created_at) AS status FROM workflow_statuses GROUP BY physical_object_id) AS x "+
			"INNER JOIN workflow_statuses on (workflow_statuses.physical_object_id = x.physical_object_id AND x.status = workflow_statuses.created_at) "+
			"WHERE workflow_statuses.status_name in (#{status.map(&:inspect).join(', ')})) as y INNER JOIN physical_objects on physical_object_id = physical_objects.id"+
		(digitized ? " WHERE physical_objects.digitized = true" : "")
		ActiveRecord::Base::connection.execute(sql).first[0]
	}

	FREEZER_AD_STRIP_VALS = ControlledVocabulary.where(model_attribute: ':ad_strip').order('value DESC').limit(3).collect{ |cv| cv.value } if ActiveRecord::Base.connection.table_exists? 'controlled_vocabularies'

	MEDIA_TYPES = ['Moving Image', 'Recorded Sound', 'Still Image', 'Text', 'Three Dimensional Object', 'Software', 'Mixed Material']

	NEW_MEDIUMS = ['Film', 'Video', 'Recorded Sound', 'Equipment/Technology']

	def self.per_page
		100
	end

	def media_types
		MEDIA_TYPES
	end

	def media_type_mediums
		NEW_MEDIUMS
	end

	# def current_workflow_status
	# 	workflow_statuses.last
	# end

	def current_location
		current_workflow_status.status_name
	end

	def previous_location
		workflow_statuses[workflow_statuses.size - 2]&.status_name
	end

	def workflow
		current_workflow_status&.workflow_type
	end

	def group_identifier
		titles.first.id
	end

	def is_media?
		medium == 'Film' || medium == 'Video' || medium == 'Recorded Sound'
	end

	def scan_settings(component_group)
		cgpo = component_group_physical_objects.where(component_group_id: component_group.id).first
		{
				scan_resolution: cgpo.scan_resolution,
				color_space: cgpo.color_space,
				return_on_reel: cgpo.return_on_reel,
				clean: cgpo.clean
		}
	end

	# tests if the physical object is currently on IULMIA staff workflow space
	def onsite?
		current_workflow_status.workflow_type
	end

	def in_transit_from_storage?
		current_workflow_status.status_name == WorkflowStatus::PULL_REQUESTED
	end

	def in_storage?
		WorkflowStatus::STATUS_TYPES_TO_STATUSES['Storage'].include?(current_location)
	end

	def packed?
		current_workflow_status.status_name == WorkflowStatus::IN_CAGE
	end

	# need this for the ajax form that creates new titles for this physical object
	def title_text

	end
	def no_collection
		self.collection.blank?
	end

	def who_requested
		pull_requests.last.requester
	end
	# where (IN ALF!!!) the PO should be stored
	def storage_location
		stats = workflow_statuses.where("status_name in (#{WorkflowStatus::STATUS_TYPES_TO_STATUSES['Storage'].map{ |s| "'#{s}'"}.join(',')})").order('created_at ASC')
		# anything with ad_strip > 2.0 must go to the freezer. If it's never been in the freezer if must go to awaiting freezer first for prep.
		# If it was last in the freezer, it should be returned to the freezer. Otherwise, the item is returned to its last storage location,
		# or ingested if it has yet to be put anywhere in storage
		if stats.size > 0
			if self.specific.has_attribute?(:ad_strip) && FREEZER_AD_STRIP_VALS.include?(self.specific.ad_strip)
				(stats.last.status_name == WorkflowStatus::IN_FREEZER ? WorkflowStatus::IN_FREEZER : WorkflowStatus::AWAITING_FREEZER)
			else
				stats.last.status_name
			end
		else
			if self.specific.class == Film && self.specific.ad_strip && FREEZER_AD_STRIP_VALS.include?(self.specific.ad_strip)
				WorkflowStatus::AWAITING_FREEZER
			else
				WorkflowStatus::IN_STORAGE_INGESTED
			end
		end
	end

	def missing?
		current_location == WorkflowStatus::MISSING
	end

	def ingested_by_alf?
		last = workflow_statuses.where("status_name in (#{WorkflowStatus::STATUS_TYPES_TO_STATUSES['Storage'].map{ |s| "'#{s}'"}.join(',')})").order('created_at DESC').limit(1).first
		!last.nil? && last.status_name == WorkflowStatus::IN_STORAGE_INGESTED
	end

	def notify_alf
		ingested_by_alf? && (storage_location == WorkflowStatus::IN_FREEZER || storage_location == WorkflowStatus::AWAITING_FREEZER)
	end


	# title_text, series_title_text, and collection_text are all necessary for javascript autocomplete on these fields for
	# forms. They provide a display value for the title/series/collection but are never set directly - the id of the model record
	# is set and passed as the param for assignment
	def titles_text
		#self.title.title_text if self.title
		self.titles.collect{ |t| t.title_text }.join(", ") unless self.titles.nil?
	end

	def series_title_text
		self.title.series.title if self.title && self.title.series
	end

	def dates_text
		self.physical_object_dates.collect{ |d| "#{d.date} [#{d.type}]" }.join(', ') unless self.physical_object_dates.nil?
	end

	def series_id
		self.title.series.id if self.title && self.title.series
  end

	def collection_text
		self.collection.name if self.collection
  end

  def generations_text
		if self.medium == 'Film'
			self.specific.humanize_boolean_fields(Film::GENERATION_FIELDS)
		elsif self.medium == 'Video'
			self.specific.humanize_boolean_fields(Video::GENERATION_FIELDS)
		elsif self.medium == 'Recorded Sound'
			self.specific.humanize_boolean_fields(RecordedSound::GENERATION_FIELDS)
		else
			raise "Unsupported Physical Object Format: #{self.medium}"
		end
	end


	# HUMANIZE methods - these are for generation human readable text that reflects the boolean values set to true for the
	# field 'categories' (Versions, Generations, Base, etc)
	def humanize_generations_fields
		if self.medium == 'Film'
			self.specific.humanize_boolean_fields(Film::GENERATION_FIELDS)
		elsif self.medium == 'Video'
			self.specific.humanize_boolean_fields(Video::GENERATION_FIELDS)
		elsif medium == 'Recorded Sound'
			self.specific.humanize_boolean_fields(RecordedSound::GENERATION_FIELDS)
		else
			raise "Unsupported Physical Object Format: #{self.medium}"
		end
	end
	def humanize_version_fields
		if self.medium == 'Film'
			self.specific.humanize_boolean_fields(Film::VERSION_FIELDS)
		elsif self.medium == 'Video'
			self.specific.humanize_boolean_fields(Video::VERSION_FIELDS)
		elsif medium == 'Recorded Sound'
			self.specific.humanize_boolean_fields(RecordedSound::VERSION_FIELDS)
		else
			raise "Unsupported Physical Object Format: #{self.medium}"
		end
	end
	def humanize_base_fields
		if self.medium == 'Film'
			self.specific.humanize_boolean_fields(Film::BASE_FIELDS)
		elsif self.medium == 'Video'
			# not a boolean field for Video
			self.specific.base
		elsif self.medium == 'Recorded Sound'
			self.specific.base
		else
			raise "Unsupported Physical Object Format: #{self.medium}"
		end
	end
	def humanize_stock_fields
		if self.medium == 'Film'
			self.specific.humanize_boolean_fields(Film::STOCK_FIELDS)
		elsif self.medium == 'Video'
			self.specific.stock
		elsif self.medium = 'Recorded Sound'
			self.specific.stock
		else
			raise "Unsupported Physical Object Format: #{self.medium}"
		end
	end
	def humanize_color_fields
		if self.medium == 'Film'
			self.specific.humanize_boolean_fields(Film::COLOR_FIELDS)
		elsif self.medium == 'Video'
			self.specific.humanize_boolean_fields(Video::COLOR_FIELDS)
		elsif self.specific.medium = 'Recorded Sound'
			'N/A'
		else
			raise "Unsupported Physical Object Format: #{self.medium}"
		end
	end
	def humanize_picture_type_fields
		if self.medium == 'Film'
			self.specific.humanize_boolean_fields(Film::PICTURE_TYPE_FIELDS)
		elsif self.medium == 'Video'
			self.specific.humanize_boolean_fields(Video::PICTURE_TYPE_FIELDS)
		elsif self.medium == 'Recorded Sound'
			'N/A'
		else
			raise "Unsupported Physical Object Format: #{self.medium}"
		end
	end
	def humanize_aspect_ratio_fields
		if self.medium == 'Film'
			self.specific.humanize_boolean_fields(Film::ASPECT_RATIO_FIELDS)
		elsif self.medium == 'Video'
			self.specific.humanize_boolean_fields(Video::ASPECT_RATIO_FIELDS)
		elsif self.medium == 'Recorded Sound'
			'N/A'
		else
			raise "Unsupported Physical Object Format: #{self.medium}"
		end
	end
	def humanize_sound_format_fields
		if self.medium == 'Film'
			self.specific.humanize_boolean_fields(Film::SOUND_FORMAT_FIELDS)
		elsif self.medium == 'Video'
			self.specific.humanize_boolean_fields(Video::SOUND_FORMAT_FIELDS)
		elsif self.medium == 'Recorded Sound'
			'N/A'
		else
			raise "Unsupported Physical Object Format: #{self.medium}"
		end
	end
	def humanize_sound_content_fields
		if self.medium == 'Film'
			self.specific.humanize_boolean_fields(Film::SOUND_CONTENT_FIELDS)
		elsif self.medium == 'Video'
			self.specific.humanize_boolean_fields(Video::SOUND_CONTENT_FIELDS)
		elsif self.specific.medium == 'Recorded Sound'
			self.specific.humanize_boolean_fields(RecordedSound::SOUND_CONTENT_FIELDS)
		else
			raise "Unsupported Physical Object Format: #{self.medium}"
		end
	end
	def humanize_sound_configuration_fields
		if self.medium == 'Film'
			self.specific.humanize_boolean_fields(Film::SOUND_CONFIGURATION_FIELDS)
		elsif self.medium == 'Video'
			self.specific.humanize_boolean_fields(Video::SOUND_CONFIGURATION_FIELDS)
		elsif self.medium == 'Recorded Sound'
			self.specific.humanize_boolean_fields(RecordedSound::SOUND_CONFIGURATION_FIELDS)
		else
			raise "Unsupported Physical Object Format: #{self.medium}"
		end
	end
	# End HUMANIZE methods comment



  def belongs_to_title?(title_id)
    PhysicalObjectTitle.where(physical_object_id: id, title_id: title_id).size > 0
  end

	# checks to see if any other physical objects that belong to this objects active component group are not at the same point in the workflow
	# returns either false if there are no other physical objects in this objects active component group that are at different workflow statuses
	# or an array of those physical objects at different workflow statuses
	def waiting_active_component_group_members?
		if active_component_group.nil?
			false
		else
			list = active_component_group.physical_objects.select{ |p| p != self && self.current_workflow_status != p.current_workflow_status }
			return list.size == 0 ? false : list
		end
	end

	# checks whether there are any other physical objects in this objects active component group who are at the same place in the workflow
	def same_active_component_group_members?
		if active_component_group.nil?
			false
		else
			li = active_component_group.physical_objects.select{ |p| p != self && self.current_workflow_status == p.current_workflow_status }
			return li.size == 0 ? false : li
		end
	end

	# duration is input as hh:mm:ss but stored as seconds
	def duration=(time)
    if time.blank?
      super(nil)
    else
      super(time.split(':').map { |a| a.to_i }.inject(0) { |a, b| a * 60 + b})
    end
  end

	# duration is viewed as hh:mm:ss
  def duration
    unless super.nil?
      hh_mm_sec(super)
    end
	end

  # returns true if the specified text is formated as h:mm:ss where h, mm, and ss are integer values
  def valid_duration?(text)
    ! /^[0-9]+:[0-9]{2,}:[0-9]{2,}$/.match(text).nil?
  end

  # returns true of the text is formatted as "x of y" where x and y are either integers or a '?'
  def valid_reel_number?(text)
    ! /^[0-9\?]+ of [0-9\?]$/.match(text).nil?
  end

	def original_identifiers_text
		oit = ""
		physical_object_original_identifiers.each_with_index do |id, i|
      (i == physical_object_original_identifiers.size - 1) ? (oit << "#{id.identifier}") : (oit << "#{id.identifier}, ")
		end
		oit
	end

	def medium_name
		medium
	end

	def sound_only?
		return (medium == 'film' && (generation_separation_master || generation_optical_sound_track))
	end

	def current_scan_settings
		if active_component_group.nil?
			nil
		else
			component_group_physical_objects.where(component_group_id: active_component_group.id).first
		end
	end

  def test_after_create
    puts "\n\nAfter Creation: #{self.created_at}\n\n"
  end

  def test_after_validation
    puts "\n\nAfter Validation: #{self.created_at}\n\n"
  end

  def test_before_save
    puts "\n\nBefore Save: #{self.created_at}\n\n"
  end

  def test_after_save
    puts "\n\nAfter Save: #{self.created_at}\n\n"
	end

	def active_scan_settings
		if !active_component_group.nil?
			active_component_group.component_group_physical_objects.where(physical_object_id: self.id).first
		end
	end

	def created_at
		date_inventoried
	end
	def created_at=(val)
		super
	end

	def estimated_duration_in_sec
		if footage.blank? || gauge.blank?
			0
		else
			(PhysicalObjectsHelper::GAUGES_TO_FRAMES_PER_FOOT[gauge] * footage) / 24
		end
	end

	def specific_matches_medium?(medium)
		self.specific.class.to_s.downcase == medium.downcase
	end

	# this method differs slightly from WorkflowStatus.in_active_workflow in that it tests against not being In Storage
	# TODO: WorkflowStatus needs to be updated (and reliant code modified) to
	def in_active_workflow?
		!active_component_group.nil? && !current_workflow_status.is_storage_status?
	end

	# There was a bug that allowed title records to be deleted while there were associated physical objects (leaving bad
	# entries in physical_object_titles) This method returns an array of EXISTING title ids for the physical object and,
	# additionally, deletes and physical_object_titles that references non-existent title ids
	def actual_title_ids
		# physical_object_titles.each do |pt|
    #   if pt.title.nil?
    #     pt.delete
    #   end
    # end
    physical_object_titles.pluck(:title_id)
	end

	def film?
		medium == 'Film'
	end
	def video?
		medium == 'Video'
	end
	def equipement_technology?
		medium == "Equipment/Technology"
	end

  # a helper for concatenating MEDIUM with additional medium specific info. For instance, a 35mm Film would be
  # displayed as 'Film 35mm'
  def format
    if [Film, Video, RecordedSound, EquipmentTechnology].include?(self.specific.class)
      "#{self.medium} (#{self.specific.gauge})"
    else
      raise "Unsupported Medium... #{self.specific}"
    end
	end

	def humanize_boolean_generation_fields
		self.specific.humanize_boolean_fields(self.specific.class.const_get(:GENERATION_FIELDS))
	end

end
