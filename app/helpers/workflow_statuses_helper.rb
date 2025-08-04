module WorkflowStatusesHelper
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

  # 7/2025 - discovered 19 physical objects with current workflow status of "ALF (non MDPI)" which was the value
  # of IN_WORKFLOW_ALF  before 5/2024 when it was changed to it's current value. These 19 physical objects were corrected
  # by migration 20250729190844_alf_non_mdpi_status.rb which added an additional workflow status with note indicating the
  # correction.
  OLD_IN_WORKFLOW_ALF = "ALF (non MDPI)"

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
end
