class MemnonDigiprovCollector
  require 'net/http'
  require 'uri'

  def my_logger
    @@mdc_logger ||= Logger.new("#{Rails.root}/log/memnon_digiprov_collector.log", 10, 50.megabytes)
  end

  def collect_shelf_in_thread(cage_shelf_id)
    Thread.new {
      sleep 1
      collect_shelf(cage_shelf_id)
    }
  end

  def collect_shelf(cage_shelf_id)
    cs = CageShelf.find(cage_shelf_id)
    raise "Couldn't find cage shelf with id: #{cage_shelf_id}" if cs.nil?
    cs.physical_objects.each do |p|
      collect_object(p, cs)
    end
  end

  def collect_object(p, cs)
    #begin
      PhysicalObject.transaction do
        mdpi = p.mdpi_barcode
        dig_url = Settings.digitized_url.gsub("<MDPI_BARCODE>", mdpi.to_s)
        p.update(digitized: successful_digitization?(get(dig_url)))

        # overwrite any digiprovs from this cage shelf/physical object combination as they are unique
        # Video and Recorded Sound were digitized before Filmdb existed so there is no cage shelf id for some calls

        Digiprov.where(physical_object_id: p.id, cage_shelf_id: (cs.nil? ? nil : cs.id)).delete_all
        xml_url = Settings.memnon_xml_url.gsub("<MDPI_BARCODE>", mdpi.to_s)
        dp = Digiprov.new(physical_object: p, digital_provenance_text: get(xml_url).body, cage_shelf_id: (cs.nil? ? nil : cs.id))
        dp.save
      end
    # rescue => e
    #   my_logger.fatal(e.message)
    #   my_logger.fatal(e.backtrace.join('\n'))
    # end
  end

  def get(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(Settings.pod_qc_user, Settings.pod_qc_pass)
    http.request(request)
  end

  private
  def successful_digitization?(xml)
    xml.body.include?("<digital_workflow_category>Succeeded</digital_workflow_category>")
  end

end