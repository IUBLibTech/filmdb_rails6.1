# module for automatically logging when an object is deleted. The included(base) ensures that when the ActiveRecord class
# includes this module, that it's before_destroy callback is hooked into log_deletion.
module DeleteLogger

  # This is what hooks in the callbacks on all ActiveRecord
  def self.included(base)
    base.class_eval do
      before_destroy :log_deletion
    end
  end


  def log_deletion
    object_id = self.id
    who_deleted = User.current_username
    object_type = self.class.to_s
    hri = ""
    if self.class == Cage
      hri = "#{self.identifier} - top: #{self.top_shelf.identifier}, middle: #{self.middle_shelf.identifier}, bottom: #{self.bottom_shelf.identifier}"
    elsif self.class == CageShelf
      hri = "#{self.identifier}"
    elsif self.class ==Collection
      hri = "#{self.name}"
    elsif self.class ==ComponentGroup
      hri = "#{self.title.title_text}, PO barcodes: #{self.physical_objects.collect{|p| p.iu_barcode}}, Group Type: #{self.group_type}"
    elsif self.class ==ControlledVocabulary
      hri = "Type: #{self.model_type}, Attribute: #{self.model_attribute}, Value: #{self.value}"
    elsif self.class ==Film
      hri = "#{self.iu_barcode} : #{self.mdpi_barcode}"
    elsif self.class ==Language
      hri = "PO: #{self.physical_object.iu_barcode}, Language: #{self.language}, Type: #{self.language_type}"
    elsif self.class ==PhysicalObject
      hri = "#{self.iu_barcode} : #{self.mdpi_barcode}"
    elsif self.class ==PhysicalObjectDate
      cv = self.controlled_vocabulary
      hri = "PO: #{self.physical_object.iu_barcode}, Type: #{cv.value}]"
    elsif self.class ==PhysicalObjectOriginalIdentifier
      hri ="PO: #{self.physical_object.iu_barcode}, #{self.identifier}"
    elsif self.class ==Series
      hri = "#{self.title}"
    elsif self.class ==Spreadsheet
      hri ="File: #{self.filename}, Success?: #{self.successful_upload?}"
    elsif self.class ==SpreadsheetSubmission
      hri = "File: #{self.spreadsheet.filename}, Upload attempt: #{self.created_at}"
    elsif self.class ==Title
      hri = "Title: #{self.title_text}, From Spreadsheet?: #{self.spreadsheet ? self.spreadsheet.filename : "no"}"
    elsif self.class ==TitleCreator
      hri = "Title: #{self.title.title_text}, Name: #{self.name}, Role: #{self.role}"
    elsif self.class == TitleDate
      hri = "Title: #{self.title.title_text}, Date: #{self.date_text}, Type: #{self.date_type}"
    elsif self.class ==TitleForm
      hri = "Title: #{self.title.title_text}, Form: #{self.form}"
    elsif self.class ==TitleGenre
      hri = "Title: #{self.title.title_text}, Genre: #{self.genre}"
    elsif self.class ==TitleLocation
      hri = "Title: #{self.title.title_text}, Location: #{self.location}"
    elsif self.class ==TitleOriginalIdentifier
      hri = "Title: #{self.title.title_text}, Identifier: #{self.identifier}, Type: #{self.identifier_type}"
    elsif self.class ==TitlePublisher
      hri = "Title: #{self.title.title_text}, Name: #{self.name}, Publisher Type: #{self.publisher_type}"
    elsif self.class ==Unit
      hri = "Name: #{self.name}, Abbreviation: #{self.abbreviation}, Institution: #{self.institution}"
    elsif self.class ==User
      hri = "Username: #{self.username}, Name: #{self.first_name +' '+self.last_name}, Active?: #{self.active?}"
    elsif self.class ==ValueCondition
      hri = "PO: #{self.physical_object.iu_barcode}, Type: #{self.condition_type}, Value: #{self.value}"
    elsif self.class ==Video
      hri = "#{self.iu_barcode} : #{self.mdpi_barcode}"
    elsif self.class ==WorkflowStatus
      hri = "PO: #{self.physical_object.iu_barcode}, Status: #{self.status_name}, CG: [#{self.component_group.group_type}]"
    else
      hri = "Deleting an object that there is no case statement for... #{self.class}"
    end
    DeleteLogEntry.new(table_id: object_id, object_type: object_type, who_deleted: who_deleted, human_readable_identifier: hri).save!
  end
end

