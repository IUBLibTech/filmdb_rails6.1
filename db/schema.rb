# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2025_01_31_162830) do

  create_table "accompanying_documentations", charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "location"
    t.text "description"
    t.integer "title_id"
    t.integer "series_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "photo_link"
  end

  create_table "boolean_conditions", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "physical_object_id"
    t.string "condition_type"
    t.text "comment"
    t.text "fixed_comment"
    t.bigint "fixed_user_id"
    t.boolean "active", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cage_shelf_physical_objects", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "physical_object_id"
    t.bigint "cage_shelf_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cage_shelves", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "cage_id"
    t.bigint "mdpi_barcode"
    t.string "identifier"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "returned", default: false
    t.datetime "shipped"
    t.datetime "returned_date"
    t.index ["mdpi_barcode"], name: "index_cage_shelves_on_mdpi_barcode", unique: true
  end

  create_table "cages", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "identifier"
    t.text "notes"
    t.bigint "top_shelf_id"
    t.bigint "middle_shelf_id"
    t.bigint "bottom_shelf_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "ready_to_ship", default: false
    t.boolean "shipped", default: false
  end

  create_table "collections", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "unit_id"
    t.text "summary"
    t.boolean "accessible"
    t.text "accessible_notes"
    t.integer "current_ownership_and_control"
    t.integer "transfer_of_ownership"
  end

  create_table "component_group_physical_objects", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "component_group_id"
    t.bigint "physical_object_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "scan_resolution"
    t.string "clean"
    t.boolean "hand_clean_only"
    t.boolean "return_on_reel"
    t.string "color_space"
  end

  create_table "component_groups", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "title_id", null: false
    t.string "group_type", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "group_summary"
    t.text "scan_resolution"
    t.string "clean", default: "Yes"
    t.boolean "hand_clean_only", default: false
    t.boolean "hd"
    t.boolean "return_on_reel", default: false
    t.string "color_space"
  end

  create_table "controlled_vocabularies", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "model_type"
    t.string "model_attribute"
    t.string "value"
    t.boolean "default"
    t.integer "menu_index", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "active_status", default: true
  end

  create_table "delayed_jobs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "delete_log_entries", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "table_id"
    t.string "object_type"
    t.string "human_readable_identifier"
    t.string "who_deleted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "digiprovs", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "physical_object_id"
    t.text "digital_provenance_text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "cage_shelf_id"
  end

  create_table "edge_codes", charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "code", limit: 3
    t.integer "physical_object_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "equipment_technologies", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.boolean "type_camera"
    t.boolean "type_camera_accessory"
    t.boolean "type_editor"
    t.boolean "type_flatbed"
    t.boolean "type_lens"
    t.boolean "type_light_reader"
    t.boolean "type_photo_equipment"
    t.boolean "type_projection_screen"
    t.boolean "type_projector"
    t.boolean "type_rewind"
    t.boolean "type_shrinkage_gauge"
    t.boolean "type_squawk_box"
    t.boolean "type_splicer"
    t.boolean "type_supplies"
    t.boolean "type_synchronizer"
    t.boolean "type_viewer"
    t.boolean "type_video_deck"
    t.boolean "type_other"
    t.text "type_other_text"
    t.string "related_media_format"
    t.string "manufacturer"
    t.string "model"
    t.string "serial_number"
    t.string "box_number"
    t.text "summary"
    t.text "production_year"
    t.string "production_location"
    t.decimal "cost_estimate", precision: 10, scale: 2
    t.text "cost_notes"
    t.string "photos_url"
    t.text "external_reference_links"
    t.string "working_condition"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "original_notes_from_donor"
    t.boolean "film_gauge_8mm"
    t.boolean "film_gauge_super_8mm"
    t.boolean "film_gauge_9_5mm"
    t.boolean "film_gauge_16mm"
    t.boolean "film_gauge_super_16mm"
    t.boolean "film_gauge_28mm"
    t.boolean "film_gauge_35mm"
    t.boolean "film_gauge_35_32mm"
    t.boolean "film_gauge_70mm"
    t.boolean "film_gauge_other"
    t.boolean "video_gauge_1_inch_videotape"
    t.boolean "video_gauge_1_2_inch_videotape"
    t.boolean "video_gauge_1_4_inch_videotape"
    t.boolean "video_gauge_2_inch_videotape"
    t.boolean "video_gauge_betacam"
    t.boolean "video_gauge_betacam_sp"
    t.boolean "video_gauge_betacam_sx"
    t.boolean "video_gauge_betamax"
    t.boolean "video_gauge_blu_ray_disc"
    t.boolean "video_gauge_cartrivision"
    t.boolean "video_gauge_d1"
    t.boolean "video_gauge_d2"
    t.boolean "video_gauge_d3"
    t.boolean "video_gauge_d5"
    t.boolean "video_gauge_d6"
    t.boolean "video_gauge_d9"
    t.boolean "video_gauge_dct"
    t.boolean "video_gauge_digital_betacam"
    t.boolean "video_gauge_digital8"
    t.boolean "video_gauge_dv"
    t.boolean "video_gauge_dvcam"
    t.boolean "video_gauge_dvcpro"
    t.boolean "video_gauge_dvd"
    t.boolean "video_gauge_eiaj_cartridge"
    t.boolean "video_gauge_evd_videodisc"
    t.boolean "video_gauge_hdcam"
    t.boolean "video_gauge_hi8"
    t.boolean "video_gauge_laserdisc"
    t.boolean "video_gauge_mii"
    t.boolean "video_gauge_minidv"
    t.boolean "video_gauge_hdv"
    t.boolean "video_gauge_super_video_cd"
    t.boolean "video_gauge_u_matic"
    t.boolean "video_gauge_universal_media_disc"
    t.boolean "video_gauge_v_cord"
    t.boolean "video_gauge_vhs"
    t.boolean "video_gauge_vhs_c"
    t.boolean "video_gauge_svhs"
    t.boolean "video_gauge_video8_aka_8mm_video"
    t.boolean "video_gauge_vx"
    t.boolean "video_gauge_videocassette"
    t.boolean "video_gauge_open_reel_videotape"
    t.boolean "video_gauge_optical_video_disc"
    t.boolean "video_gauge_other"
    t.boolean "video_gauge_svhs_c"
    t.boolean "video_gauge_ced"
    t.boolean "recorded_sound_gauge_open_reel_audiotape"
    t.boolean "recorded_sound_gauge_grooved_analog_disc"
    t.boolean "recorded_sound_gauge_1_inch_audio_tape"
    t.boolean "recorded_sound_gauge_1_2_inch_audio_cassette"
    t.boolean "recorded_sound_gauge_1_4_inch_audio_cassette"
    t.boolean "recorded_sound_gauge_1_4_inch_audio_tape"
    t.boolean "recorded_sound_gauge_2_inch_audio_tape"
    t.boolean "recorded_sound_gauge_8_track"
    t.boolean "recorded_sound_gauge_aluminum_disc"
    t.boolean "recorded_sound_gauge_audio_cassette"
    t.boolean "recorded_sound_gauge_audio_cd"
    t.boolean "recorded_sound_gauge_dat"
    t.boolean "recorded_sound_gauge_dds"
    t.boolean "recorded_sound_gauge_dtrs"
    t.boolean "recorded_sound_gauge_flexi_disc"
    t.boolean "recorded_sound_gauge_grooved_dictabelt"
    t.boolean "recorded_sound_gauge_lacquer_disc"
    t.boolean "recorded_sound_gauge_magnetic_dictabelt"
    t.boolean "recorded_sound_gauge_mini_cassette"
    t.boolean "recorded_sound_gauge_pcm_betamax"
    t.boolean "recorded_sound_gauge_pcm_u_matic"
    t.boolean "recorded_sound_gauge_pcm_vhs"
    t.boolean "recorded_sound_gauge_piano_roll"
    t.boolean "recorded_sound_gauge_plastic_cylinder"
    t.boolean "recorded_sound_gauge_shellac_disc"
    t.boolean "recorded_sound_gauge_super_audio_cd"
    t.boolean "recorded_sound_gauge_vinyl_recording"
    t.boolean "recorded_sound_gauge_wax_cylinder"
    t.boolean "recorded_sound_gauge_wire_recording"
    t.boolean "recorded_sound_gauge_1_8_inch_audio_tape"
    t.boolean "recorded_sound_gauge_minidisc"
  end

  create_table "films", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.boolean "first_edition"
    t.boolean "second_edition"
    t.boolean "third_edition"
    t.boolean "fourth_edition"
    t.boolean "abridged"
    t.boolean "short"
    t.boolean "long"
    t.boolean "sample"
    t.boolean "preview"
    t.boolean "revised"
    t.boolean "version_original"
    t.boolean "captioned"
    t.boolean "excerpt"
    t.boolean "catholic"
    t.boolean "domestic"
    t.boolean "trailer"
    t.boolean "english"
    t.boolean "television"
    t.boolean "x_rated"
    t.string "gauge"
    t.boolean "generation_projection_print"
    t.boolean "generation_a_roll"
    t.boolean "generation_b_roll"
    t.boolean "generation_c_roll"
    t.boolean "generation_d_roll"
    t.boolean "generation_answer_print"
    t.boolean "generation_composite"
    t.boolean "generation_duplicate"
    t.boolean "generation_edited"
    t.boolean "generation_fine_grain_master"
    t.boolean "generation_intermediate"
    t.boolean "generation_kinescope"
    t.boolean "generation_magnetic_track"
    t.boolean "generation_mezzanine"
    t.boolean "generation_negative"
    t.boolean "generation_optical_sound_track"
    t.boolean "generation_original"
    t.boolean "generation_outs_and_trims"
    t.boolean "generation_positive"
    t.boolean "generation_reversal"
    t.boolean "generation_separation_master"
    t.boolean "generation_work_print"
    t.boolean "generation_mixed"
    t.string "reel_number"
    t.string "can_size"
    t.integer "footage"
    t.boolean "base_acetate"
    t.boolean "base_polyester"
    t.boolean "base_nitrate"
    t.boolean "base_mixed"
    t.boolean "stock_agfa"
    t.boolean "stock_ansco"
    t.boolean "stock_dupont"
    t.boolean "stock_orwo"
    t.boolean "stock_fuji"
    t.boolean "stock_gevaert"
    t.boolean "stock_kodak"
    t.boolean "stock_ferrania"
    t.boolean "picture_not_applicable"
    t.boolean "picture_silent_picture"
    t.boolean "picture_mos_picture"
    t.boolean "picture_composite_picture"
    t.boolean "picture_intertitles_only"
    t.boolean "picture_credits_only"
    t.boolean "picture_picture_effects"
    t.boolean "picture_picture_outtakes"
    t.boolean "picture_kinescope"
    t.string "frame_rate"
    t.boolean "color_bw_bw_toned"
    t.boolean "color_bw_bw_tinted"
    t.boolean "color_bw_color_ektachrome"
    t.boolean "color_bw_color_kodachrome"
    t.boolean "color_bw_color_technicolor"
    t.boolean "color_bw_color_anscochrome"
    t.boolean "color_bw_color_eco"
    t.boolean "color_bw_color_eastman"
    t.boolean "aspect_ratio_1_33_1"
    t.boolean "aspect_ratio_1_37_1"
    t.boolean "aspect_ratio_1_66_1"
    t.boolean "aspect_ratio_1_85_1"
    t.boolean "aspect_ratio_2_35_1"
    t.boolean "aspect_ratio_2_39_1"
    t.boolean "aspect_ratio_2_59_1"
    t.text "sound"
    t.boolean "sound_format_optical_variable_area"
    t.boolean "sound_format_optical_variable_density"
    t.boolean "sound_format_magnetic"
    t.boolean "sound_format_digital_sdds"
    t.boolean "sound_format_digital_dts"
    t.boolean "sound_format_digital_dolby_digital"
    t.boolean "sound_format_sound_on_separate_media"
    t.boolean "sound_content_music_track"
    t.boolean "sound_content_effects_track"
    t.boolean "sound_content_dialog"
    t.boolean "sound_content_composite_track"
    t.boolean "sound_content_outtakes"
    t.boolean "sound_configuration_mono"
    t.boolean "sound_configuration_stereo"
    t.boolean "sound_configuration_surround"
    t.boolean "sound_format_optical_variable_area_maurer"
    t.boolean "sound_configuration_dual_mono"
    t.string "ad_strip"
    t.float "shrinkage"
    t.string "mold"
    t.text "missing_footage"
    t.boolean "multiple_items_in_can"
    t.boolean "color_bw_color_color"
    t.boolean "color_bw_bw_black_and_white"
    t.boolean "color_bw_bw_hand_coloring"
    t.boolean "color_bw_bw_stencil_coloring"
    t.text "captions_or_subtitles_notes"
    t.boolean "sound_format_optical"
    t.string "anamorphic"
    t.integer "track_count"
    t.boolean "generation_original_camera"
    t.boolean "generation_master"
    t.boolean "sound_format_digital_dolby_digital_sr"
    t.boolean "sound_format_digital_dolby_digital_a"
    t.boolean "stock_3_m"
    t.boolean "stock_agfa_gevaert"
    t.boolean "stock_pathe"
    t.boolean "stock_unknown"
    t.boolean "aspect_ratio_2_66_1"
    t.boolean "aspect_ratio_1_36"
    t.boolean "aspect_ratio_1_18"
    t.boolean "picture_titles"
    t.boolean "generation_other"
    t.boolean "sound_content_narration"
    t.string "close_caption"
    t.text "generation_notes"
    t.boolean "generation_interpositive"
    t.boolean "picture_text"
    t.boolean "aspect_ratio_2_55_1"
    t.boolean "sound_format_optical_variable_area_bilateral"
    t.boolean "sound_format_optical_variable_area_dual_bilateral"
    t.boolean "sound_format_optical_variable_area_unilateral"
    t.boolean "sound_format_optical_variable_area_dual_unilateral"
    t.boolean "sound_format_optical_variable_area_rca_duplex"
    t.boolean "sound_format_optical_variable_density_multiple_density"
    t.boolean "orientation_a_wind"
    t.boolean "orientation_b_wind"
    t.date "ad_strip_timestamp"
    t.boolean "color_bw_color_gaspar"
    t.boolean "stock_ilford"
    t.boolean "aspect_ratio_1_75_1"
  end

  create_table "languages", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "physical_object_id"
    t.string "language"
    t.string "language_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "modifications", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "object_type"
    t.integer "object_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "physical_object_accompanying_documentations", charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "physical_object_id"
    t.integer "accompanying_documentation_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "physical_object_dates", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "physical_object_id"
    t.bigint "controlled_vocabulary_id"
    t.string "date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "physical_object_ephemeras", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "physical_object_id"
    t.integer "ephemera_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "physical_object_old_barcodes", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "physical_object_id"
    t.bigint "iu_barcode"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "physical_object_original_identifiers", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "physical_object_id"
    t.string "identifier", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "physical_object_pull_requests", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "physical_object_id"
    t.bigint "pull_request_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "physical_object_titles", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "title_id"
    t.bigint "physical_object_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["physical_object_id", "title_id"], name: "index_physical_object_titles_on_physical_object_id_and_title_id", unique: true
  end

  create_table "physical_objects", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "date_inventoried"
    t.bigint "inventoried_by"
    t.string "location"
    t.bigint "collection_id"
    t.string "media_type"
    t.bigint "iu_barcode", null: false
    t.integer "spreadsheet_id"
    t.string "alternative_title"
    t.text "accompanying_documentation"
    t.text "notes"
    t.bigint "unit_id"
    t.string "medium"
    t.bigint "modified_by"
    t.string "access"
    t.integer "duration"
    t.text "format_notes"
    t.string "condition_rating"
    t.text "condition_notes"
    t.string "research_value"
    t.text "research_value_notes"
    t.text "conservation_actions"
    t.bigint "mdpi_barcode"
    t.text "accompanying_documentation_location"
    t.text "miscellaneous"
    t.string "title_control_number"
    t.bigint "cage_shelf_id"
    t.bigint "component_group_id"
    t.boolean "in_freezer", default: false
    t.boolean "awaiting_freezer", default: false
    t.string "alf_shelf"
    t.string "catalog_key"
    t.boolean "digitized"
    t.bigint "current_workflow_status_id"
    t.string "compilation"
    t.integer "actable_id"
    t.string "actable_type"
    t.text "photo_link"
    t.index ["actable_id", "actable_type"], name: "index_physical_objects_on_actable_id_and_actable_type", unique: true
    t.index ["current_workflow_status_id"], name: "index_physical_objects_on_current_workflow_status_id"
    t.index ["iu_barcode", "mdpi_barcode"], name: "index_physical_objects_on_iu_barcode_and_mdpi_barcode", unique: true
  end

  create_table "pod_pushes", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.text "response", size: :long
    t.bigint "cage_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pull_requests", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "created_by_id"
    t.string "filename"
    t.text "file_contents", size: :medium
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "caia_soft"
    t.text "json_payload", size: :medium
    t.boolean "caia_soft_upload_success"
    t.text "caia_soft_response", size: :medium
  end

  create_table "recorded_sounds", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.boolean "version_first_edition"
    t.boolean "version_second_edition"
    t.boolean "version_third_edition"
    t.boolean "version_fourth_edition"
    t.boolean "version_abridged"
    t.boolean "version_anniversary"
    t.boolean "version_domestic"
    t.boolean "version_english"
    t.boolean "version_excerpt"
    t.boolean "version_long"
    t.boolean "version_original"
    t.boolean "version_reissue"
    t.boolean "version_revised"
    t.boolean "version_sample"
    t.boolean "version_short"
    t.boolean "version_x_rated"
    t.string "gauge"
    t.boolean "generation_copy_access"
    t.boolean "generation_dub"
    t.boolean "generation_duplicate"
    t.boolean "generation_intermediate"
    t.boolean "generation_master"
    t.boolean "generation_master_distribution"
    t.boolean "generation_master_production"
    t.boolean "generation_off_air_recording"
    t.boolean "generation_original_recording"
    t.boolean "generation_preservation"
    t.boolean "generation_work_tapes"
    t.boolean "generation_other"
    t.string "sides"
    t.string "part"
    t.string "size"
    t.string "base"
    t.string "stock"
    t.text "detailed_stock_information"
    t.boolean "multiple_items_in_can"
    t.string "playback"
    t.boolean "sound_content_type_composite_track"
    t.boolean "sound_content_type_dialog"
    t.boolean "sound_content_type_effects_track"
    t.boolean "sound_content_type_music_track"
    t.boolean "sound_content_type_outtakes"
    t.boolean "sound_configuration_dual_mono"
    t.boolean "sound_configuration_mono"
    t.boolean "sound_configuration_stereo"
    t.boolean "sound_configuration_surround"
    t.boolean "sound_configuration_unknown"
    t.boolean "sound_configuration_other"
    t.string "mold"
    t.integer "actable_id"
    t.string "actable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "noise_reduction"
    t.string "capacity"
    t.text "generation_notes"
    t.string "track_configuration"
  end

  create_table "series", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "title"
    t.string "summary"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "created_by_id"
    t.bigint "modified_by_id"
    t.string "production_number"
    t.string "date"
    t.integer "total_episodes"
    t.bigint "spreadsheet_id"
  end

  create_table "shipping_metadata", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "workflow_status_id"
    t.text "notes"
    t.bigint "shipped_by"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "spread_sheet_searches", id: :integer, charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.integer "user_id"
    t.string "title_text"
    t.string "series_name"
    t.string "date_text"
    t.string "publisher_text"
    t.string "creator_text"
    t.string "summary_text"
    t.string "location_text"
    t.string "subject_text"
    t.integer "collection_id"
    t.string "digitized_status"
    t.boolean "completed"
    t.float "query_runtime"
    t.float "spreadsheet_runtime"
    t.integer "percent_complete"
    t.text "error_message"
    t.float "request_ts"
    t.string "file_location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "genre"
    t.string "form"
    t.integer "medium_filter"
  end

  create_table "spreadsheet_submissions", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "spreadsheet_id"
    t.integer "submission_progress"
    t.boolean "successful_submission"
    t.text "failure_message", size: :long
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "spreadsheets", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "filename", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "successful_upload", default: false
    t.index ["filename"], name: "index_spreadsheets_on_filename", unique: true
  end

  create_table "title_creators", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "title_id"
    t.string "name"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "title_dates", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "title_id"
    t.string "date_text"
    t.string "date_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "start_date"
    t.boolean "start_month_present"
    t.boolean "start_day_present"
    t.boolean "extra_text"
    t.boolean "start_date_is_approximation"
    t.date "end_date"
    t.boolean "end_date_month_present"
    t.boolean "end_date_day_present"
    t.boolean "end_date_is_approximation"
  end

  create_table "title_forms", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "title_id"
    t.string "form"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "title_genres", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "title_id"
    t.string "genre"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "title_locations", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "title_id"
    t.string "location", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "title_original_identifiers", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "title_id"
    t.string "identifier"
    t.string "identifier_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "title_publishers", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "title_id"
    t.string "name"
    t.string "publisher_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "titles", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "title_text", limit: 1024
    t.text "summary"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "series_id"
    t.bigint "spreadsheet_id"
    t.integer "series_title_index"
    t.bigint "modified_by_id"
    t.string "series_part"
    t.bigint "created_by_id"
    t.text "notes"
    t.text "subject"
    t.text "name_authority"
    t.text "country_of_origin"
    t.boolean "fully_cataloged"
    t.string "pod_group_key_identifier"
    t.string "in_copyright"
    t.string "copyright_end_date_edtf"
    t.date "copyright_end_date"
    t.boolean "copyright_verified_by_iu_cp_research"
    t.boolean "copyright_verified_by_viewing_po"
    t.boolean "copyright_verified_by_other"
    t.text "copyright_notes"
    t.string "stream_url"
  end

  create_table "units", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "abbreviation", null: false
    t.string "institution", null: false
    t.string "campus"
    t.integer "menu_index"
    t.index ["abbreviation"], name: "index_units_on_abbreviation", unique: true
  end

  create_table "users", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "username", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "role_mask", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "active", default: false
    t.string "email_address"
    t.bigint "created_in_spreadsheet"
    t.boolean "can_delete", default: false
    t.string "worksite_location"
    t.boolean "works_in_both_locations", default: false
    t.boolean "can_update_physical_object_location", default: false
    t.boolean "can_edit_users", default: false
    t.boolean "can_add_cv", default: false
    t.boolean "read_only"
  end

  create_table "value_conditions", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "physical_object_id"
    t.string "condition_type"
    t.string "value"
    t.text "comment"
    t.text "fixed_comment"
    t.bigint "fixed_user_id"
    t.boolean "active", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "videos", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.string "gauge"
    t.boolean "first_edition"
    t.boolean "second_edition"
    t.boolean "third_edition"
    t.boolean "fourth_edition"
    t.boolean "abridged"
    t.boolean "short"
    t.boolean "long"
    t.boolean "sample"
    t.boolean "revised"
    t.boolean "original"
    t.boolean "excerpt"
    t.boolean "catholic"
    t.boolean "domestic"
    t.boolean "trailer"
    t.boolean "english"
    t.boolean "non_english"
    t.boolean "television"
    t.boolean "x_rated"
    t.boolean "generation_b_roll"
    t.boolean "generation_commercial_release"
    t.boolean "generation_copy_access"
    t.boolean "generation_dub"
    t.boolean "generation_duplicate"
    t.boolean "generation_edited"
    t.boolean "generation_fine_cut"
    t.boolean "generation_intermediate"
    t.boolean "generation_line_cut"
    t.boolean "generation_master"
    t.boolean "generation_master_production"
    t.boolean "generation_master_distribution"
    t.boolean "generation_off_air_recording"
    t.boolean "generation_original"
    t.boolean "generation_picture_lock"
    t.boolean "generation_rough_cut"
    t.boolean "generation_stock_footage"
    t.boolean "generation_submaster"
    t.boolean "generation_work_tapes"
    t.boolean "generation_work_track"
    t.boolean "generation_other"
    t.string "reel_number"
    t.string "size"
    t.string "recording_standard"
    t.string "maximum_runtime"
    t.string "base"
    t.string "stock"
    t.boolean "picture_type_not_applicable"
    t.boolean "picture_type_silent_picture"
    t.boolean "picture_type_mos_picture"
    t.boolean "picture_type_composite_picture"
    t.boolean "picture_type_credits_only"
    t.boolean "picture_type_picture_effects"
    t.boolean "picture_type_picture_outtakes"
    t.boolean "picture_type_other"
    t.string "playback_speed"
    t.boolean "image_color_bw"
    t.boolean "image_color_color"
    t.boolean "image_color_mixed"
    t.boolean "image_color_other"
    t.boolean "image_aspect_ratio_4_3"
    t.boolean "image_aspect_ratio_16_9"
    t.boolean "image_aspect_ratio_other"
    t.boolean "captions_or_subtitles"
    t.text "notes"
    t.boolean "silent"
    t.boolean "sound_format_type_magnetic"
    t.boolean "sound_format_type_digital"
    t.boolean "sound_format_type_sound_on_separate_media"
    t.boolean "sound_format_type_other"
    t.boolean "sound_content_type_music_track"
    t.boolean "sound_content_type_effects_track"
    t.boolean "sound_content_type_dialog"
    t.boolean "sound_content_type_composite_track"
    t.boolean "sound_content_type_outtakes"
    t.boolean "sound_configuration_mono"
    t.boolean "sound_configuration_stereo"
    t.boolean "sound_configuration_surround"
    t.boolean "sound_configuration_other"
    t.boolean "sound_noise_redux_dolby_a"
    t.boolean "sound_noise_redux_dolby_b"
    t.boolean "sound_noise_redux_dolby_c"
    t.boolean "sound_noise_redux_dolby_s"
    t.boolean "sound_noise_redux_dolby_sr"
    t.boolean "sound_noise_redux_dolby_nr"
    t.boolean "sound_noise_redux_dolby_hx"
    t.boolean "sound_noise_redux_dolby_hx_pro"
    t.boolean "sound_noise_redux_dbx"
    t.boolean "sound_noise_redux_dbx_type_1"
    t.boolean "sound_noise_redux_dbx_type_2"
    t.boolean "sound_noise_redux_high_com"
    t.boolean "sound_noise_redux_high_com_2"
    t.boolean "sound_noise_redux_adres"
    t.boolean "sound_noise_redux_anrs"
    t.boolean "sound_noise_redux_dnl"
    t.boolean "sound_noise_redux_dnr"
    t.boolean "sound_noise_redux_cedar"
    t.boolean "sound_noise_redux_none"
    t.string "mold"
    t.text "playback_issues_video_artifacts"
    t.text "playback_issues_audio_artifacts"
    t.text "missing_footage"
    t.text "captions_or_subtitles_notes"
    t.text "generation_notes"
    t.string "sound"
    t.integer "tape_capacity"
    t.text "detailed_stock_information"
    t.boolean "image_aspect_ratio_5_4"
    t.boolean "image_aspect_ratio_16_10"
    t.boolean "image_aspect_ratio_21_9"
  end

  create_table "workflow_statuses", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "physical_object_id"
    t.string "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "workflow_type"
    t.string "whose_workflow"
    t.string "status_name"
    t.integer "component_group_id"
    t.integer "external_entity_id"
    t.bigint "created_by"
    t.text "comment"
    t.index ["physical_object_id"], name: "index_workflow_statuses_on_physical_object_id"
    t.index ["status_name"], name: "index_workflow_statuses_on_status_name"
  end

end
