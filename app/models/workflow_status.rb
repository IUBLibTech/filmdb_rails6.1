class WorkflowStatus < ApplicationRecord
	belongs_to :physical_object
	belongs_to :component_group, optional: true
	belongs_to :user, class_name: 'User', foreign_key: 'created_by'

	after_create :update_physical_object

	WORKFLOW_TYPES = ['Storage', 'In Workflow', 'Shipped', 'Deaccessioned']
	WORK_LOCATIONS = ['ALF', 'Wells 052']

	MDPI = 'MDPI'
	IULMIA = 'IULMIA'

	# all status names
	AWAITING_FREEZER = 'Awaiting Freezer'
	BEST_COPY_ALF = 'Evaluation (ALF)'
	BEST_COPY_WELLS = 'Evaluation (Wells)'
	BEST_COPY_MDPI_WELLS = 'Evaluation (Wells)'
	DEACCESSIONED = 'Deaccessioned'
	IN_CAGE = 'In Cage (ALF)'
	IN_STORAGE_INGESTED = 'In Storage (Ingested)'
	IN_STORAGE_AWAITING_INGEST = 'In Storage (Awaiting Ingest)'
	IN_FREEZER = 'In Freezer'
	IN_WORKFLOW_ALF = 'In Workflow (ALF)'
	IN_WORKFLOW_WELLS = 'In Workflow (Wells)'
	ISSUES_SHELF = 'Issues Shelf (ALF)'
	JUST_INVENTORIED_WELLS = 'Just Inventoried (Wells)'
	JUST_INVENTORIED_ALF = 'Just Inventoried (ALF)'
	MOLD_ABATEMENT = 'Mold Abatement'
	MISSING = 'Missing'
	PULL_REQUESTED = 'Pull Requested'
	QUEUED_FOR_PULL_REQUEST = 'Queued for Pull Request'
	RECEIVED_FROM_STORAGE_STAGING = 'Returned to Pull Requested'
	SHIPPED_EXTERNALLY = 'Shipped Externally'
	TWO_K_FOUR_K_SHELVES = "Digitization Shelf"
	WELLS_TO_ALF_CONTAINER = 'Wells to ALF Container'

	ALL_STATUSES = [IN_STORAGE_INGESTED, IN_STORAGE_AWAITING_INGEST, IN_FREEZER, AWAITING_FREEZER, MOLD_ABATEMENT, MISSING,	IN_CAGE, QUEUED_FOR_PULL_REQUEST,	PULL_REQUESTED,
	                RECEIVED_FROM_STORAGE_STAGING, TWO_K_FOUR_K_SHELVES, ISSUES_SHELF, BEST_COPY_ALF, IN_WORKFLOW_WELLS, SHIPPED_EXTERNALLY, DEACCESSIONED, JUST_INVENTORIED_WELLS,
	                JUST_INVENTORIED_ALF, BEST_COPY_WELLS, BEST_COPY_MDPI_WELLS, WELLS_TO_ALF_CONTAINER, IN_WORKFLOW_ALF]
	WELLS_STATUSES = [JUST_INVENTORIED_WELLS, BEST_COPY_WELLS, IN_WORKFLOW_WELLS]
  STATUS_TYPES_TO_STATUSES = {
		# physical location is ALF
		'Storage' => [IN_STORAGE_INGESTED, IN_STORAGE_AWAITING_INGEST, IN_FREEZER, AWAITING_FREEZER ],
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

	PULLABLE_STORAGE = [IN_STORAGE_INGESTED, IN_STORAGE_AWAITING_INGEST, IN_FREEZER, AWAITING_FREEZER]
	SPREADSHEET_START_LOCATIONS = [IN_STORAGE_AWAITING_INGEST, IN_STORAGE_INGESTED, IN_FREEZER, AWAITING_FREEZER, JUST_INVENTORIED_ALF, JUST_INVENTORIED_WELLS, MOLD_ABATEMENT, MISSING]

	STATUSES_TO_NEXT_WORKFLOW = {
		IN_STORAGE_INGESTED => [QUEUED_FOR_PULL_REQUEST, IN_FREEZER, AWAITING_FREEZER, MISSING],
		IN_STORAGE_AWAITING_INGEST => [QUEUED_FOR_PULL_REQUEST, IN_STORAGE_INGESTED, IN_FREEZER, AWAITING_FREEZER, MISSING],
		IN_FREEZER => [QUEUED_FOR_PULL_REQUEST, MISSING, AWAITING_FREEZER, IN_STORAGE_INGESTED],
		AWAITING_FREEZER => [QUEUED_FOR_PULL_REQUEST, IN_FREEZER, MISSING, IN_STORAGE_INGESTED],
		MOLD_ABATEMENT => [RECEIVED_FROM_STORAGE_STAGING, IN_STORAGE_INGESTED, IN_STORAGE_AWAITING_INGEST, IN_FREEZER, AWAITING_FREEZER, BEST_COPY_ALF, MISSING, ISSUES_SHELF],
		MISSING => ALL_STATUSES,
		IN_CAGE => [SHIPPED_EXTERNALLY, TWO_K_FOUR_K_SHELVES, MISSING, ISSUES_SHELF],
		QUEUED_FOR_PULL_REQUEST => ([PULL_REQUESTED, MISSING] + PULLABLE_STORAGE),
		PULL_REQUESTED => (PULLABLE_STORAGE + [
				IN_WORKFLOW_WELLS, BEST_COPY_ALF, BEST_COPY_WELLS, BEST_COPY_MDPI_WELLS, ISSUES_SHELF,
				TWO_K_FOUR_K_SHELVES, DEACCESSIONED, MOLD_ABATEMENT, MISSING, IN_WORKFLOW_ALF
		]),
		RECEIVED_FROM_STORAGE_STAGING => [TWO_K_FOUR_K_SHELVES, MISSING, ISSUES_SHELF],
		TWO_K_FOUR_K_SHELVES => ([IN_CAGE, MISSING, ISSUES_SHELF] + PULLABLE_STORAGE),
		ISSUES_SHELF =>  ([TWO_K_FOUR_K_SHELVES, DEACCESSIONED, BEST_COPY_ALF, MISSING] + (PULLABLE_STORAGE + [MOLD_ABATEMENT])),
		BEST_COPY_ALF => (PULLABLE_STORAGE + [MOLD_ABATEMENT, MISSING] + [TWO_K_FOUR_K_SHELVES, DEACCESSIONED, ISSUES_SHELF]),
		BEST_COPY_WELLS => (PULLABLE_STORAGE + [DEACCESSIONED, MOLD_ABATEMENT, MISSING, ISSUES_SHELF]),
		BEST_COPY_MDPI_WELLS => (PULLABLE_STORAGE + [WELLS_TO_ALF_CONTAINER, MOLD_ABATEMENT, MISSING, ISSUES_SHELF]),
		IN_WORKFLOW_WELLS => ((PULLABLE_STORAGE + [MOLD_ABATEMENT]) + [SHIPPED_EXTERNALLY, DEACCESSIONED, MISSING, WELLS_TO_ALF_CONTAINER]),
		IN_WORKFLOW_ALF => ((PULLABLE_STORAGE + [MOLD_ABATEMENT]) + [SHIPPED_EXTERNALLY, DEACCESSIONED, MISSING]),
		WELLS_TO_ALF_CONTAINER => [TWO_K_FOUR_K_SHELVES, IN_FREEZER, MISSING, ISSUES_SHELF],
		SHIPPED_EXTERNALLY => (PULLABLE_STORAGE + [IN_WORKFLOW_WELLS, MISSING]),
		DEACCESSIONED => [],
		JUST_INVENTORIED_WELLS => [IN_STORAGE_AWAITING_INGEST, IN_STORAGE_INGESTED, AWAITING_FREEZER, IN_WORKFLOW_WELLS, IN_FREEZER, MISSING, MOLD_ABATEMENT, ISSUES_SHELF, WELLS_TO_ALF_CONTAINER, BEST_COPY_MDPI_WELLS],
		JUST_INVENTORIED_ALF => [IN_STORAGE_AWAITING_INGEST, IN_STORAGE_INGESTED, IN_FREEZER, AWAITING_FREEZER, MOLD_ABATEMENT, RECEIVED_FROM_STORAGE_STAGING, BEST_COPY_ALF, MISSING, ISSUES_SHELF, TWO_K_FOUR_K_SHELVES]
	}

	# Constructs the next status that a physical object will be moving to based on status_name. Validates whether the location
	# change is allows based on STATUSES_TO_NEXT_WORKFLOW definitations unless override is true
	def self.build_workflow_status(status_name, physical_object, override=false)
		current = physical_object.current_workflow_status
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
				component_group_id: nil)
		else
			ws = WorkflowStatus.new(
				physical_object_id: physical_object.id,
				workflow_type: which_workflow_type(status_name),
				whose_workflow: '',
				status_name: status_name,
				component_group_id: ((STATUS_TYPES_TO_STATUSES['Storage'] + [DEACCESSIONED, JUST_INVENTORIED_ALF, JUST_INVENTORIED_WELLS]).include?(status_name) ? nil : physical_object.active_component_group&.id))
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
		ws.user = User.current_user_object
		# need to clear the active component group if the physical object is being updated to a status that is not "in workflow" - mold abatement in this case does not count as 'storage'
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

	def self.is_storage_status?(status_name)
		s = workflow_type_from_status(status_name)
		s != nil && s == 'Storage'
	end

	def is_storage_status?
		WorkflowStatus.is_storage_status?(self.status_name)
  end

	def missing?
		status_name == MISSING
	end

  def self.in_workflow?(status_name)
    workflow_type_from_status(status_name) == 'In Workflow'
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
