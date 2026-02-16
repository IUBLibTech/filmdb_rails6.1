module CaiaSoftStatusHelper
  include WorkflowStatusesHelper
  ### CaiaSoft Statuses from API docs: https://portal.caiasoft.com/apiguide.php?serv=restapi&rec=4&oper=statuslist ###
  RESTRICTED_API_ACCESS = "Item Restricted from this API Key"
  NOT_FOUND = "Item not Found"
  WAITING_ON_INCOMING_ACCESSION_STREAM = "Item Waiting on Incoming Accession Stream"
  IN_ACCESSION_PROCESS = "Item In Accession Process"
  COMMITTED = "Item Committed"
  WAITING_ON_RETRIEVAL_QUEUE = "Item Waiting on the Retrieval Request Queue"
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
  

end
