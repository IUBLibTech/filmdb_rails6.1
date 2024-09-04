module LocationHelper
  require 'axlsx'

  def self.do_it
    path = "#{Rails.root}/tmp/IULMIA_BarcodeCheck_reviewed_03.csv" if path.blank?
    read_spreadsheet(path)
    bad = iterate
    file = "#{Rails.root}/tmp/previous_barcodes.csv"
    headers = ["IU Barcode", "Location", "Previous Barcode(s)"]
    CSV.open(file, 'w') do |csv|
      csv << headers
      bad.each do |row|
        csv << row
      end
    end
  end

  def self.read_spreadsheet(path)
    begin
      return unless File.exists? path
      @csv = CSV.read(path, headers: false)
    rescue
      @opened_file = File.open(path, "r:ISO-8859-1:UTF-8")
      @csv = CSV.parse(@opened_file, headers: false)
    end
  end

  def self.iterate
    User.current_username = "jaalbrec" # this, to satisfy validation on WorkflowStatus
    prev_bsc = []
    @csv.each_with_index do |row, index|
      next if index == 0
      po = PhysicalObject.where(iu_barcode: row[0].to_i).first
      po = PhysicalObjectOldBarcode.where(iu_barcode: row[0].to_i ).first.physical_object if po.nil?
      raise "No PO with barcode: #{row[0]}" if po.nil?
      new_loc = row[1]
      current = po.current_workflow_status.status_name
      if new_loc == "Need Previous Barcode"
        old = po.physical_object_old_barcodes.collect { |obc| obc.iu_barcode }.join(",")
        row << old
        prev_bsc << row
      elsif WorkflowStatus::ALL_STATUSES.include?(new_loc)
        next if po.current_workflow_status.status_name == new_loc
        ws = WorkflowStatus.build_workflow_status(new_loc, po, true)
        po.workflow_statuses << ws
        po.current_workflow_status = ws
        po.save!
        puts "#{po.iu_barcode} changed: #{current} -> #{po.current_workflow_status.status_name}"
      else
        if new_loc == WorkflowStatus::IN_WORKFLOW_ALF
          next if po.current_workflow_status.status_name == new_loc
          new_loc == WorkflowStatus::IN_WORKFLOW_ALF
          ws = WorkflowStatus.build_workflow_status(new_loc, po, true)
          po.workflow_statuses << ws
          po.current_workflow_status = ws
          po.save!
          puts "#{po.iu_barcode} changed: #{current} -> #{po.current_workflow_status.status_name}"
        else
          raise "Unknown workflow status location: #{new_loc}"
        end
      end
    end
    prev_bsc
  end

end
