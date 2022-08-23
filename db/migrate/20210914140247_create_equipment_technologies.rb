class CreateEquipmentTechnologies < ActiveRecord::Migration[4.2]
  def change
    create_table :equipment_technologies do |t|
      t.boolean :type_camera
      t.boolean :type_camera_accessory
      t.boolean :type_editor
      t.boolean :type_flatbed
      t.boolean :type_lens
      t.boolean :type_light_reader
      t.boolean :type_photo_equipment
      t.boolean :type_projection_screen
      t.boolean :type_projector
      t.boolean :type_rewind
      t.boolean :type_shrinkage_gauge
      t.boolean :type_squawk_box
      t.boolean :type_splicer
      t.boolean :type_supplies
      t.boolean :type_synchronizer
      t.boolean :type_viewer
      t.boolean :type_video_deck
      t.boolean :type_other
      t.text :type_other_text

      t.string :related_media_format

      t.string :manufacturer
      t.string :model
      t.string :serial_number

      t.string :box_number
      t.text :summary
      t.date :production_year
      t.string :production_location

      t.string :cost_estimate
      t.text :cost_notes

      t.string :photos_url
      t.text :external_reference_links

      t.string :working_condition

      t.timestamps null: false
    end
  end
end
