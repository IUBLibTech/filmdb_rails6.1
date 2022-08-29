module EquipmentTechnologyHelper
  include ApplicationHelper
  require "axlsx"

  def gen_eq_spreadsheet
    x = Axlsx::Package.new
    wb = x.workbook
    eq = wb.add_worksheet(name: "Equipment Technology")

    headers = [
    "IU Barcode", "Collection", "Accompanying Documentation",
    "Type", "Manufacturer", "Model", "Serial #", "Related Media Formats", "Box #", "Production Year", "Production Location",
    "Original Identifiers",
    "Summary", "Cost Estimate Notes", "Cost Estimate", "Link to Photographs", "External Resource Materials",
    "Original Notes From Donor", "Working Condition", "Overall Condition", "Condition Notes", "Research Value",
    "Research Value Notes", "Conservation Actions"
    ]
    eq.add_row(headers)
    pos = EquipmentTechnology.all
    pos.each do |p|
      eq.add_row( [
        p.iu_barcode, p.collection&.name, p.accompanying_documentation, p.humanize_boolean_fields(EquipmentTechnology::TYPE_FIELDS),
        p.manufacturer, p.model, p.serial_number, "#{p.related_media_format} (#{p.related_media_format_gauges})", p.box_number,
        p.production_year, p.production_location, p.original_identifiers_text, p.summary, p.cost_notes, p.cost_estimate,
        p.photos_url, p.external_reference_links, p.original_notes_from_donor, p.working_condition, p.condition_rating,
        p.condition_notes, p.research_value, p.research_value_notes, p.conservation_actions
      ])
    end
    success = x.serialize(eq_file_location)
    if success
      send_file eq_file_location
    else
      raise "Could not write spreadsheet..."
    end
  end

end
