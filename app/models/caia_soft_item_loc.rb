class CaiaSoftItemLoc < ApplicationRecord
  belongs_to :physical_object

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

end
