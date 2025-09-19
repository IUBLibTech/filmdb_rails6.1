# The background process that checks whether Filmdb "In Storage (Awaiting Ingest)" physical objects have been accessioned
# in CaiaSoft. If yes, updates their storage location to "In Storage (Ingested)"
class CaiaSoftItemLoc < ApplicationRecord
  include AlfHelper
  include CaiaSoftStatusHelper
  include Delayed::RecurringJob
  require "csv"

  belongs_to :physical_object

  run_every 1.minute
  run_at Time.now
  queue "awaiting_ingest_check"

  # definitions for the CaiaSoft nightly back CSV file headers
  HEADER_BARCODE = "Item Barcode"
  HEADER_STATUS = "Item Status"
  HEADER_CONTAINER = "Container"
  HEADER_ADDRESS = "Address"
  # location is a concatenation of the columns <aisle-side-ladder-step>
  HEADER_AISLE = "Aisle"
  HEADER_SIDE = "Side"
  HEADER_LADDER = "Ladder"
  HEADER_STEP = "Step"
  HEADER_FOOTPRINT = "Footprint"
  HEADER_CONTAINER_TYPE = "Container Type"
  HEADER_COLLECTION = "Collection"
  HEADER_MATERIAL = "Material"
  HEADER_ACCESSION_DATE = "Accession Date"
  HEADER_DEACCESSION_DATE = "De-accession Date"

  def perform
    Logger.info("CaiaSoftItemLoc#perform - checking if any physical objects that are awaiting ingest have been accessioned by ALF")
    CaiaSoftItemLoc.check_awaiting_storage
  end

  # a utility function that takes a JSON entry for a specific physical object from a CaiaSoft itemloc or itemloclist response,
  # and sets the CaiaSoftItemLoc attributes to their current value
  def copy_json(json)
    self.iu_barcode = json["barcode"].to_i
    self.status = json["status"]
    self.container = json["container"]
    self.address = json["address"]
    self.location =  json["location"]
    self.footprint = json["footprint"]
    self.container_type = json["container_type"]
    self.collection = json["collection"]
    self.material = json["material"]
    self.accession_date = json["accession date"]
    self.last_status_update  = json["last status update"]
  end


  def self.check_awaiting_storage
    all = PhysicalObject.joins(:current_workflow_status).where("status_name = ?", WorkflowStatus::IN_STORAGE_AWAITING_INGEST )
    # update all caiasoft itemlocs
    all.slice(500).each do |pos|
      cs_itemloclist(pos)
      pos.each do |po|
        status = status_from_itemloclist(po.iu_barcode)
        # update the WorkflowStatus to in storage ingested
        if status == IN_ALF
          ws = WorkflowStatus.build_workflow_status(WorkflowStatus::IN_STORAGE_INGESTED, po, true)
          po.current_workflow_status = ws
          po.workflow_statuses << ws
          po.save!
        end
      end
    end
  end

  def self.sync_all_physical_objects
    Logger.info "Beginning sync of all PhysicalObjects with CaiaSoft"
    start = Time.now
    all = PhysicalObject.where(medium: ["Film", "Video", "Recorded Sound"]).includes(:caia_soft_item_loc)
    all.slice(500).each do |pos|
      cs_itemloclist(pos)
    end
    duration = Time.now - start
    Logger.info "CaiaSoft sync took #{Time.at(duration).utc.strftime("%H:%M:%S")}"
  end

  def self.parse_nightly_backup(path = "#{Rails.root}/tmp/EODINV_iualf_20250727_101511.txt")
    @bad = []
    puts "Parsing CSV: #{path}"
    csv = CSV.read(path, headers: true)
    puts "Sorting CSV..."
    csv = csv.sort_by{|row| row[HEADER_BARCODE].to_i}
    puts "Processing Physical Objects..."
    all_pos = PhysicalObject.where(medium: ["Film", "Video", "Recorded Sound"]).includes(:caia_soft_item_loc).order(iu_barcode: :asc)
    all_pos.each_with_index do |po, index|
      puts "\t#{index} of #{all_pos.size}"
      row = binary_search_csv(csv, po.iu_barcode.to_s, "Item Barcode")
      begin
        if row
          # CaiaSoft appends ' on <date>' to the 'status' field for many of the statuses for instance:
          # "Item has been Deaccessioned on 05/14/2013", strip the date off
          row[HEADER_STATUS] = strip_date_from_status(row[HEADER_STATUS])
          create_update_itemloc(row, po)
        else
          create_update_not_found_itemloc(po)
        end
      rescue
        @bad << [po.iu_barcode, row]
      end
    end
    @bad
  end

  # Creates a CaiaSoftItemLoc from the nightly backup for PhysicalObjects that are not found in the CSV file (ones not accessioned in CS)
  def self.create_update_not_found_itemloc(po)
    mismatch = !AlfHelper.equivalent_statuses?(NOT_FOUND, po.current_workflow_status)
    if po.caia_soft_item_loc.nil?
      CaiaSoftItemLoc.new(iu_barcode: po.iu_barcode, physical_object_id: po.id, status: NOT_FOUND, mismatch: mismatch).save!
    else
      po.caia_soft_item_loc.update!(iu_barcode: po.iu_barcode, status: NOT_FOUND, mismatch: mismatch)
    end
  end

  # takes a row from the CaiaSoft nightly backup CSV file and its matching physical object and either updates the
  # CaiaSoftItemLoc for it or creates one if it doesn't exist. Also compares the current status to the PO's location
  # in Filmdb and sets the "mismatch" field if the two systems are not in agreement
  def self.create_update_itemloc(row, po)
    csil = po.caia_soft_item_loc
    if csil.nil?
      csil = CaiaSoftItemLoc.new(iu_barcode: po.iu_barcode, physical_object_id: po.id)
    end
    csil.status = row[HEADER_STATUS]
    csil.container = row[HEADER_CONTAINER]
    csil.address = row[HEADER_ADDRESS]
    # need to concatenate 4 fields from the nighly backup to create location field as it's displayed in the itemloc/itemloclist API
    csil.location = "#{row[HEADER_AISLE]}-#{row[HEADER_SIDE]}-#{row[HEADER_LADDER]}-#{row[HEADER_STEP]}"
    csil.footprint = row[HEADER_FOOTPRINT]
    csil.container_type = row[HEADER_CONTAINER_TYPE]
    csil.collection = row[HEADER_COLLECTION]
    csil.material = row[HEADER_MATERIAL]
    csil.accession_date = row[HEADER_ACCESSION_DATE]
    csil.mismatch = !AlfHelper.equivalent_statuses?(row[HEADER_STATUS], po.current_workflow_status)
    csil.save!
  end

  # Google AI wrote this. Not bad!
  def self.binary_search_csv(sorted_csv_data, target_value, search_column)
    low = 0
    high = sorted_csv_data.length - 1
    while low <= high
      mid = (low + high) / 2
      mid_value = sorted_csv_data[mid][search_column]

      if mid_value == target_value
        return sorted_csv_data[mid] # Found the row
      elsif mid_value < target_value
        low = mid + 1
      else
        high = mid - 1
      end
    end

    nil # Not found
  end

  def self.strip_date_from_status(status)
    WITH_DATE_IN_CSV.each do |real|
      if status.start_with?(real)
        return real
      end
    end
    status
  end


end
