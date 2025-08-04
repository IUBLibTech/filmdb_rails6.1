module CaiaSoftStatusHelper
  include WorkflowStatusesHelper
  ### CaiaSoft Statuses from API docs: https://portal.caiasoft.com/apiguide.php?serv=restapi&rec=4&oper=statuslist ###
  RESTRICTED_API_ACCESS = "Item Restricted from this API Key"
  NOT_FOUND = "Item not Found"
  WAITING_ON_INCOMING_ACCESSION_STREAM = "Item Waiting on Incoming Accession Stream"
  IN_ACCESSION_PROCESS = "Item In Accession Process"
  COMMITTED = "Item Committed"
  DEACCESSIONED = "Item has been Deaccessioned"
  OUT_OF_ALF = "Out on Physical Retrieval"
  PULLED_E_RETRIEVAL = "Pulled for E-Retrieval"
  OUT_ON_SHIP_SERVICE = "Out on SH-I-P Service" # stands for "Special Handling, Internal & Preservation"
  IN_ALF = "Item In at Rest"
  IN_QUEUE_REFILE = "In Queue for Refile"
  IN_QUEUE_PHYSICAL_RETRIEVAL = "In Queue for Physical Retrieval"
  IN_QUEUE_E_RETRIEVAL = "In Queue for E-Retrieval"
  IN_QUEUE_SHIP_SERVICE = "In Queue for SH-I-P Service"
  IN_QUEUE_DEACCESSION = "In Queue for De-accession"

  # CS appends the date of the action to the status field for all of these, but only in the nightly backup CSV files, NOT
  # in the API calls... When parsing a backup file, make sure to convert the "Item has been Deaccessioned on 05/14/2013"
  # to just "Item has been Deaccessioned"
  WITH_DATE_IN_CSV = [DEACCESSIONED, OUT_OF_ALF, PULLED_E_RETRIEVAL, OUT_ON_SHIP_SERVICE, IN_QUEUE_REFILE,
               IN_QUEUE_PHYSICAL_RETRIEVAL, IN_QUEUE_E_RETRIEVAL, IN_QUEUE_SHIP_SERVICE, IN_QUEUE_DEACCESSION]


  ### Equivalency maps CS status to Filmdb Workflow Statuses ###
  # these are not one to one, but rather one to many. For instance NOT_FOUND in caiasoft could mean many things
  # in Filmdb:
  #   * the item hasn't been accessioned in CS but is physically in ALF
  #   * the item hasn't been accessioned in CS but is physically in IULMIA workspace (either Wells 052 or ALF)
  #   * the item has never been sent to ALF and is MISSING in IULMIA workflow
  #   * the item is a freezer item and is either physically in ALF or in IULMIA workspace
  #   * the item is Equipement/Technology and not stored in ALF (ever) - could be in workflow or in OFFSITE storage
  #   * etc
  #
  EQUIVALENCIES = {
    RESTRICTED_API_ACCESS => [], # no correlation to filmdb - if we see this status it means the API key was changed/deleted!!! Contact Adam
    NOT_FOUND => [
      JUST_INVENTORIED_ALF, JUST_INVENTORIED_WELLS, AWAITING_FREEZER,
      IN_FREEZER, IN_STORAGE_AWAITING_INGEST, IN_STORAGE_INGESTED_OFFSITE,
      MISSING, SHIPPED_EXTERNALLY, DEACCESSIONED, IN_WORKFLOW_ALF,
      IN_WORKFLOW_WELLS
    ],
    WAITING_ON_INCOMING_ACCESSION_STREAM => [IN_STORAGE_AWAITING_INGEST],
    IN_ACCESSION_PROCESS => [IN_STORAGE_AWAITING_INGEST],
    COMMITTED => [IN_STORAGE_INGESTED],
    DEACCESSIONED => [DEACCESSIONED],
    OUT_OF_ALF => [
      IN_WORKFLOW_WELLS, IN_WORKFLOW_ALF, SHIPPED_EXTERNALLY,
      MISSING, BEST_COPY_MDPI_WELLS, BEST_COPY_WELLS, BEST_COPY_ALF
    ],
    PULLED_E_RETRIEVAL => [IN_STORAGE_INGESTED], # FIXME: check if this is correct
    OUT_ON_SHIP_SERVICE => [IN_STORAGE_INGESTED], # FIXME: stands for "Special Handling, Internal & Preservation" - should it be treated like it's still in ALF hands?
    IN_ALF => [IN_STORAGE_INGESTED],
    IN_QUEUE_REFILE => [IN_STORAGE_INGESTED],
    IN_QUEUE_PHYSICAL_RETRIEVAL => [PULL_REQUESTED],
    IN_QUEUE_E_RETRIEVAL => [IN_STORAGE_INGESTED],
    IN_QUEUE_SHIP_SERVICE => [IN_STORAGE_INGESTED], # FIXME: check in relation to OUT_ON_SHIP_SERVICE
    IN_QUEUE_DEACCESSION => [DEACCESSIONED]
  }
end
