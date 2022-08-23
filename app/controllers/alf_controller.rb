require 'csv'
class AlfController < ApplicationController

  def index

  end

  def barcode_upload

  end

  def process_barcode_upload
    @file = params[:file]
    if @file.blank?
      flash.now[:warning] = 'You must specify a barcode file.'
      render 'alf/barcode_upload'
    else
      contents = File.read(@file.tempfile)
      bcs = contents.split /\s+/
      download = CSV.generate( headers: true) do |csv|
        csv << ["Barcode", "Title", "Series", "Collection", "Reel Number"]
        bcs.each do |bc|
          po = PhysicalObject.where(iu_barcode: bc).first
          if po.nil?
            csv << ["Invalid Barcode: #{bc}", '', '', '', '']
          else
            po = po.specific
            csv << [bc, po.titles_text, po.titles.collect{|t| t.series ? t.series.title : ''}.join(" | "), po.collection.name, po&.reel_number]
          end
        end
      end
      response.headers['Content-Type'] = 'text/csv'
      response.headers['Content-Disposition'] = 'attachment; filename=invoice.csv'
      send_data download, filename: "#{Time.now.strftime("%Y%m%d")}_alf3move.csv"
    end
  end

end
