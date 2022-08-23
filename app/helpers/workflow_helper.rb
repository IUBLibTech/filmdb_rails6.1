module WorkflowHelper

  def pos_to_cvs(physical_objects)
    headers = ["IU Barcode", "Title(s)", "Unit", "Gauge", "Can Size", "Footage", "Duration", "AD Strip"]
    CSV.generate(headers: true) do |csv|
      csv << headers
      physical_objects.each do |p|
        csv << [p.iu_barcode, p.titles_text, p.unit.abbreviation, p.gauge, p.can_size, p.footage, p.duration, p.ad_strip]
      end
    end
  end
end
