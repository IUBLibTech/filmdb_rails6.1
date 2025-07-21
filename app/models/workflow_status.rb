class WorkflowStatus < ApplicationRecord
	belongs_to :physical_object
	belongs_to :component_group, optional: true
	belongs_to :user, class_name: 'User', foreign_key: 'created_by'

	after_create :update_physical_object

	WORKFLOW_TYPES = ['Storage', 'In Workflow', 'Shipped', 'Deaccessioned']
	WORK_LOCATIONS = [User::WORK_LOCATION_ALF, User::WORK_LOCATION_WELLS ]


	MDPI = 'MDPI'
	IULMIA = 'IULMIA'

	# all status names
	AWAITING_FREEZER = 'Awaiting Freezer'
	BEST_COPY_ALF = 'Evaluation (ALF)'
	BEST_COPY_WELLS = 'Evaluation (Wells)'
	BEST_COPY_MDPI_WELLS = 'Evaluation (Wells)'
	DEACCESSIONED = 'Deaccessioned'
	IN_CAGE = 'In Cage (ALF)'
	IN_FREEZER = 'In Freezer'
	IN_WORKFLOW_ALF = 'In Workflow (ALF)'
	IN_WORKFLOW_WELLS = 'In Workflow (Wells)'
	ISSUES_SHELF = 'Issues Shelf (ALF)'
	JUST_INVENTORIED_WELLS = 'Just Inventoried (Wells)'
	JUST_INVENTORIED_ALF = 'Just Inventoried (ALF)'
	MOLD_ABATEMENT = 'Mold Abatement'
	MISSING = 'Missing'

	# 7/2025 the values for IN_STORAGE_INGESTED and IN_STORAGE_AWAITING_INGEST were changed from OLD_IN_STORAGE_INGESTED
	# and OLD_IN_STORAGE_AWAITING_INGEST to their "NEW" counterparts. This was done because IULMIA does not store its
	# Equipement/Technology objects in ALF and it was unclear to users. The migration which corrected WorkflowStatus status_names
	# in the database will raise an error in either running the migration or rolling it back if these values are not correct
	# for the action needed.
	#
	NEW_IN_STORAGE_INGESTED = 'In ALF (Ingested)'
	NEW_IN_STORAGE_AWAITING_INGEST = 'In ALF (Awaiting Ingest)'
	OLD_IN_STORAGE_INGESTED = "In Storage (Ingested)"
	OLD_IN_STORAGE_AWAITING_INGEST = "In Storage (Awaiting Ingest)"
	IN_STORAGE_INGESTED = NEW_IN_STORAGE_INGESTED
	IN_STORAGE_AWAITING_INGEST = NEW_IN_STORAGE_AWAITING_INGEST

	PULL_REQUESTED = 'Pull Requested'
	QUEUED_FOR_PULL_REQUEST = 'Queued for Pull Request'
	RECEIVED_FROM_STORAGE_STAGING = 'Returned to Pull Requested'
	SHIPPED_EXTERNALLY = 'Shipped Externally'
	TWO_K_FOUR_K_SHELVES = "Digitization Shelf"
	WELLS_TO_ALF_CONTAINER = 'Wells to ALF Container'

	# DO NOT USE in STATUSES_TO_NEXT_WORKFLOW: this is a special storage location used for ALL Eq/Tech POs ONLY! Do not add it to
	# the rule hash because the rules hash does not differentiate between PO mediums. Anywhere an Eq/Tech needs to move here,
	# force the workflow status creation with override=true in the method
	IN_STORAGE_INGESTED_OFFSITE = "In Storage (Offsite)"


	# Workflow status locations which define a Physical Object as "active"
	ACTIVE_WORKFLOW = [PULL_REQUESTED, QUEUED_FOR_PULL_REQUEST, IN_WORKFLOW_WELLS, IN_WORKFLOW_ALF, SHIPPED_EXTERNALLY, JUST_INVENTORIED_WELLS, JUST_INVENTORIED_ALF]


	ALL_STATUSES = [IN_STORAGE_INGESTED, IN_STORAGE_AWAITING_INGEST, IN_FREEZER, AWAITING_FREEZER, MOLD_ABATEMENT, MISSING,
									IN_CAGE, QUEUED_FOR_PULL_REQUEST,	PULL_REQUESTED, RECEIVED_FROM_STORAGE_STAGING, TWO_K_FOUR_K_SHELVES,
									ISSUES_SHELF, BEST_COPY_ALF, IN_WORKFLOW_WELLS, SHIPPED_EXTERNALLY, DEACCESSIONED, JUST_INVENTORIED_WELLS,
	                JUST_INVENTORIED_ALF, BEST_COPY_WELLS, BEST_COPY_MDPI_WELLS, WELLS_TO_ALF_CONTAINER, IN_WORKFLOW_ALF]

	# The current, actively used statuses for Physical Object Filtering PhysicalObjectController#index. Some legacy locations
	# are included (MOLD_ABATEMENT for instance) because there still objects currently at these locations.
	PHYSICAL_OBJECT_STATUSES = ALL_STATUSES - [TWO_K_FOUR_K_SHELVES, IN_CAGE, ISSUES_SHELF, RECEIVED_FROM_STORAGE_STAGING, WELLS_TO_ALF_CONTAINER]

	WELLS_STATUSES = [JUST_INVENTORIED_WELLS, BEST_COPY_WELLS, IN_WORKFLOW_WELLS]


	# Any currently used workflow status that CaiaSoft reports as "Out on Physical Retrieval" or has never been ingested
	NOT_IN_ALF = [JUST_INVENTORIED_WELLS, JUST_INVENTORIED_ALF, PULL_REQUESTED, IN_WORKFLOW_WELLS, IN_WORKFLOW_ALF,
								SHIPPED_EXTERNALLY, MISSING, DEACCESSIONED, IN_FREEZER, AWAITING_FREEZER, BEST_COPY_ALF, BEST_COPY_WELLS,
								BEST_COPY_MDPI_WELLS, IN_STORAGE_AWAITING_INGEST, MOLD_ABATEMENT]


	# CAIASOFT_DENIED_LOCATIONS = [IN_STORAGE_INGESTED, AWAITING_FREEZER, IN_FREEZER, IN_WORKFLOW_WELLS, IN_WORKFLOW_ALF,
	# 														 MISSING, JUST_INVENTORIED_ALF, JUST_INVENTORIED_WELLS]
	# CURRENT_STATUSES = [IN_STORAGE_INGESTED, IN_FREEZER, MISSING, QUEUED_FOR_PULL_REQUEST, PULL_REQUESTED,
	# 										IN_WORKFLOW_WELLS, SHIPPED_EXTERNALLY, DEACCESSIONED, JUST_INVENTORIED_WELLS,
	# 										JUST_INVENTORIED_ALF, IN_WORKFLOW_ALF]

	STATUS_TYPES_TO_STATUSES = {
		# physical location is ALF
		'Storage' => [IN_STORAGE_INGESTED, IN_STORAGE_AWAITING_INGEST, IN_FREEZER, AWAITING_FREEZER, IN_STORAGE_AWAITING_INGEST, IN_STORAGE_INGESTED_OFFSITE ],
		#physical location is either ALF-IULMIA or Wells-IULMIA differentiated by WHICH_WORKFLOW values
		'In Workflow' => [QUEUED_FOR_PULL_REQUEST, PULL_REQUESTED, RECEIVED_FROM_STORAGE_STAGING, TWO_K_FOUR_K_SHELVES, ISSUES_SHELF,
		                  BEST_COPY_ALF, BEST_COPY_WELLS, BEST_COPY_MDPI_WELLS, IN_CAGE, IN_WORKFLOW_WELLS, JUST_INVENTORIED_WELLS,
											JUST_INVENTORIED_ALF, MOLD_ABATEMENT, WELLS_TO_ALF_CONTAINER, IN_WORKFLOW_ALF],
	  # physical location is the external_entity_id foreign key reference
		'Shipped' => [SHIPPED_EXTERNALLY],
		# physical location is the dumpster out back
	  'Deaccessioned' => [DEACCESSIONED],
    # physical location is anyone's guess
		'Missing' => [MISSING]
	}

	CLEAR_ACTIVE_COMPONENT_GROUP = (STATUS_TYPES_TO_STATUSES['Storage']+STATUS_TYPES_TO_STATUSES['Deaccessioned'])

	PULLABLE_STORAGE = [IN_STORAGE_AWAITING_INGEST, IN_STORAGE_INGESTED, IN_FREEZER, AWAITING_FREEZER]
	SPREADSHEET_START_LOCATIONS = [IN_STORAGE_AWAITING_INGEST, IN_STORAGE_INGESTED, IN_FREEZER, AWAITING_FREEZER, JUST_INVENTORIED_ALF, JUST_INVENTORIED_WELLS, MOLD_ABATEMENT, MISSING]

	STATUSES_TO_NEXT_WORKFLOW = {
		IN_STORAGE_INGESTED => [QUEUED_FOR_PULL_REQUEST, IN_FREEZER, AWAITING_FREEZER, MISSING],
		IN_FREEZER => [QUEUED_FOR_PULL_REQUEST, MISSING, IN_STORAGE_INGESTED],
		AWAITING_FREEZER => [QUEUED_FOR_PULL_REQUEST, IN_FREEZER, MISSING, IN_STORAGE_INGESTED],
		MISSING => [IN_WORKFLOW_ALF, IN_WORKFLOW_WELLS, IN_STORAGE_INGESTED, IN_STORAGE_AWAITING_INGEST, IN_FREEZER, AWAITING_FREEZER, DEACCESSIONED],
		QUEUED_FOR_PULL_REQUEST => ([PULL_REQUESTED, MISSING] + PULLABLE_STORAGE),
		PULL_REQUESTED => (PULLABLE_STORAGE + [IN_WORKFLOW_WELLS, IN_WORKFLOW_ALF
		]),

		IN_WORKFLOW_WELLS => (PULLABLE_STORAGE + [SHIPPED_EXTERNALLY, DEACCESSIONED, MISSING]),
		IN_WORKFLOW_ALF => (PULLABLE_STORAGE + [SHIPPED_EXTERNALLY, DEACCESSIONED, MISSING]),
		SHIPPED_EXTERNALLY => (PULLABLE_STORAGE + [IN_WORKFLOW_WELLS, IN_WORKFLOW_ALF, MISSING]),
		DEACCESSIONED => [],
		JUST_INVENTORIED_WELLS => PULLABLE_STORAGE + [SHIPPED_EXTERNALLY, DEACCESSIONED, MISSING],
		JUST_INVENTORIED_ALF => PULLABLE_STORAGE + [SHIPPED_EXTERNALLY, DEACCESSIONED, MISSING]
	}

	# Constructs the next status that a physical object will be moving to based on status_name. Validates whether the location
	# change is allows based on STATUSES_TO_NEXT_WORKFLOW definitations unless override is true
	def self.build_workflow_status(status_name, physical_object, override=false)
		current = physical_object.current_workflow_status
		current_user = User.current_user_object
		if ((current.nil? && !SPREADSHEET_START_LOCATIONS.include?(status_name)) ||	(!current.nil? && !current.valid_next_workflow?(status_name, override)))
			raise RuntimeError, "#{physical_object.current_workflow_status.type_and_location} cannot be moved into workflow status #{status_name}"
		end
		# just inventoried or ingested from spreadsheet
		if current.nil?
			ws = WorkflowStatus.new(
				physical_object_id: physical_object.id,
				workflow_type: which_workflow_type(status_name),
				whose_workflow: '',
				status_name: status_name,
				component_group_id: nil,
				user: current_user)
		else
			ws = WorkflowStatus.new(
				physical_object_id: physical_object.id,
				workflow_type: which_workflow_type(status_name),
				whose_workflow: '',
				status_name: status_name,
				component_group_id: ((STATUS_TYPES_TO_STATUSES['Storage'] + [DEACCESSIONED, JUST_INVENTORIED_ALF, JUST_INVENTORIED_WELLS]).include?(status_name) ? nil : physical_object.active_component_group&.id),
				user: current_user)
			if !physical_object.current_workflow_status&.external_entity_id.nil?
				ws.external_entity_id = previous_workflow_status.external_entity_id
			end
		end
		if ws.status_name == IN_FREEZER
			physical_object.in_freezer = true
			physical_object.awaiting_freezer = false
		elsif ws.status_name == AWAITING_FREEZER
			physical_object.in_freezer = false
			physical_object.awaiting_freezer=true
		end
		# need to clear the active component group if the physical object is being updated to a status that is not "in workflow":
		# mold abatement in this case does not count as 'storage'
		if CLEAR_ACTIVE_COMPONENT_GROUP.include? status_name
			physical_object.active_component_group = nil
		end
		ws
	end

	def valid_next_workflow?(next_workflow, override=false)
		if !override
			STATUSES_TO_NEXT_WORKFLOW[self.status_name].include?(next_workflow)
		else
			true
		end
	end

	def self.mdpi_receive_options(po)
		a = []
		if po.current_location == WorkflowStatus::WELLS_TO_ALF_CONTAINER
			a << TWO_K_FOUR_K_SHELVES
		elsif po.active_component_group.group_type == ComponentGroup::BEST_COPY_ALF
			a << BEST_COPY_ALF
			a << ISSUES_SHELF
		elsif po.active_component_group.group_type == ComponentGroup::REFORMATTING_MDPI
			a << TWO_K_FOUR_K_SHELVES
			a << ISSUES_SHELF
		end
		a.each.collect { |s| [s, s] }
	end

	def self.workflow_type_from_status(status_name)
		STATUS_TYPES_TO_STATUSES.keys.each do |key|
			if STATUS_TYPES_TO_STATUSES[key].include? status_name
				return key
			end
		end
		nil
	end

	def external?
		self.status_name == SHIPPED_EXTERNALLY
	end

	def self.is_freezer_storage?(loc)
		loc == IN_FREEZER || loc == AWAITING_FREEZER
	end


	def self.is_storage_status?(status_name)
		s = workflow_type_from_status(status_name)
		s != nil && s == 'Storage'
	end

	def is_storage_status?
		WorkflowStatus.is_storage_status?(self.status_name)
	end
	def is_freezer_storage?
		WorkflowStatus.is_freezer_storage?(self.status_name)
	end

	def missing?
		status_name == MISSING
	end

	# checks whether the WorkflowStatus is considered an "In Workflow" status
  def self.in_workflow?(status_name)
		[IN_WORKFLOW_WELLS, IN_WORKFLOW_ALF, JUST_INVENTORIED_ALF, JUST_INVENTORIED_WELLS].include? status_name
  end

  def in_workflow?
    WorkflowStatus.in_workflow?(self.status_name)
  end


	def can_be_pulled?
		STATUS_TYPES_TO_STATUSES['Storage'].include?(status_name) && status_name != MISSING && status_name != MOLD_ABATEMENT
	end

	def just_inventoried?
		[JUST_INVENTORIED_WELLS, JUST_INVENTORIED_ALF].include?(status_name)
	end

	def type_and_location
		"#{status_name}"
	end

	def location

	end

	def ==(other)
		self.class == other.class && self.status_name == other.status_name && self.whose_workflow == other.whose_workflow
	end

	def previous_sibling
		ws = self.physical_object.workflow_statuses
		index = ws.index(self)
		prev = nil
		if index > 0
			prev = ws[index - 1]
		end
		prev
	end

	def next_sibling
		ws = self.physical_object.workflow_statuses
		index = ws.index(self)
		n = nil
		if index < ws.size - 1
			n = ws[index+1]
		end
		n
	end

	private
	def update_physical_object
		physical_object.update!(current_workflow_status_id: id);
	end

	def self.find_workflow(status_name, po)
		if po.active_component_group.nil?
			#clear the MDPI IULMIA workflow when it is no longer in their workflow
			if [IN_STORAGE_INGESTED, IN_STORAGE_AWAITING_INGEST, IN_FREEZER, AWAITING_FREEZER, MISSING, MOLD_ABATEMENT, JUST_INVENTORIED_WELLS].include? status_name
				''
			else
				raise 'Missing active component group!!!'
			end
		else
			po.active_component_group.whose_workflow
		end
	end
	def self.which_workflow_type(status_name)
		STATUS_TYPES_TO_STATUSES.keys.each do |k|
			if STATUS_TYPES_TO_STATUSES[k].include? status_name
				return k
			end
		end
		return ''
	end

end
