class AddVideoControlledVocabulary < ActiveRecord::Migration[4.2]
  def up
    sizes = [
        "5 1/2 inch", "7 inch", "8 3/8 inch", "10 inch", "15 inch", "Betacam small (6¾\" × 4⅜\" × 1⅕\")", "Betacam large (10⅝\" × 6⅜\" × 1¼\")",
        "Betamax (6⅛\" × 3¾\" × 1\")", "Betamax SX", "D1", "D2 small (6¾\" × 4¼\" × 1⅓\")", "D2 large (10\" × 5⅞\" × 1⅓\")", "D3 (8¼\" × 4⅞\" × 1\")",
        "Digibeta small (6⅛\" × 3¾\" × 1\")", "Digibeta large (large: 9⅓\" × 5⅔\" × 1\")", "MiniDV (2½\" × 1⅞\" × ⅖\")", "DVC Pro small (3⅘\" × 2½\" × ½\")",
        "DVC Pro large (4⅞\" × 3\" × ½\")", "DV Cam small (2½\" × 1⅞\" × ½\")", "DV Cam large (4⅞\" × 3\" × ½\")", "HD Cam HDV",
        "U-matic small (7¼\" × 4⅝\" × 1⅕\")", "U-matic large (8⅝\" × 5⅜\" × 1⅕\")", "VHS (187mm × 103mm × 25mm)", "VHS-C", "Video8 (3⅔\" × 2⅜\" × ½\")"
    ]

    ControlledVocabulary.transaction do
      sizes.each do |s|
        ControlledVocabulary.new(model_type: "Video", model_attribute: ':size', value: s, active_status: true).save!
      end
      %w(NTSC PAL SECAM Other).each do |s|
        ControlledVocabulary.new(model_type: "Video", model_attribute: ':recording_standard', value: s, active_status: true).save!
      end
      %w(10 15 20 30 60 90 100 120 cartridge).each do |s|
        ControlledVocabulary.new(model_type: "Video", model_attribute: ':maximum_runtime', value: s, active_status: true).save!
      end
      %w(acetate polyester mixed other).each do |s|
        ControlledVocabulary.new(model_type: "Video", model_attribute: ':base', value: s, active_status: true).save!
      end
      %w(Ampex Fuji Maxell Panasonic Quantegy Scotch Sony other).each do |s|
        ControlledVocabulary.new(model_type: "Video", model_attribute: ':stock', value: s, active_status: true).save!
      end
      %w(Standard\ Play Long\ Play Extended\ Play Other).each do |s|
        ControlledVocabulary.new(model_type: "Video", model_attribute: ':playback_speed', value: s, active_status: true).save!
      end
      %w(Yes\ (isolate\ in\ mold\ bin) No Treated).each do |s|
        ControlledVocabulary.new(model_type: "Video", model_attribute: ':mold', value: s, active_status: true).save!
      end

      # rated conditions
      [ "Pack Deformation", "Water Damage", "Warp", "Splice Damage", "Dirty", "Label Damage", "Peeling", "Delamination",
        "Scratches", "Creasing", "Tape Residue", "Broken"].each do |s|
        ControlledVocabulary.new(model_type: "Video", model_attribute: ':value_condition', value: s, active_status: true).save!
      end
      # rated condition ratings
      ["1 - Minimal", "2 - Moderate", "3 - Heavy", "4 - Possibly Unplayable", "5 - Deaccession"].each do |s|
        ControlledVocabulary.new(model_type: "Video", model_attribute: ':rated_condition_rating', value: s, active_status: true).save!
      end

      # boolean conditions
      ["Soft Binder Syndrome / Sticky Shed Syndrome", "Poor Wind"].each do |s|
        ControlledVocabulary.new(model_type: "Video", model_attribute: ':boolean_condition', value: s, active_status: true).save!
      end

      # overall condition ratings
      ["1 - Excellent","2 - Minimal","3 - Moderate","4 - Heavy","5 - Possibly Unplayable","6 - Deaccession"].each do |s|
        ControlledVocabulary.new(model_type: "Video", model_attribute: ':overall_condition_rating', value: s, active_status: true).save!
      end

      # research value rating
      ["1 - High","2 - Medium","3 - Low"].each do |s|
        ControlledVocabulary.new(model_type: "Video", model_attribute: ':research_value', value: s, active_status: true).save!
      end
    end
  end
  def down
    sizes = [
        "5 1/2 inch", "7 inch", "8 3/8 inch", "10 inch", "15 inch", "Betacam small (6¾\" × 4⅜\" × 1⅕\")", "Betacam large (10⅝\" × 6⅜\" × 1¼\")",
        "Betamax (6⅛\" × 3¾\" × 1\")", "Betamax SX", "D1", "D2 small (6¾\" × 4¼\" × 1⅓\")", "D2 large (10\" × 5⅞\" × 1⅓\")", "D3 (8¼\" × 4⅞\" × 1\")",
        "Digibeta small (6⅛\" × 3¾\" × 1\")", "Digibeta large (large: 9⅓\" × 5⅔\" × 1\")", "MiniDV (2½\" × 1⅞\" × ⅖\")", "DVC Pro small (3⅘\" × 2½\" × ½\")",
        "DVC Pro large (4⅞\" × 3\" × ½\")", "DV Cam small (2½\" × 1⅞\" × ½\")", "DV Cam large (4⅞\" × 3\" × ½\")", "HD Cam HDV",
        "U-matic small (7¼\" × 4⅝\" × 1⅕\")", "U-matic large (8⅝\" × 5⅜\" × 1⅕\")", "VHS (187mm × 103mm × 25mm)", "VHS-C", "Video8 (3⅔\" × 2⅜\" × ½\")"
    ]

    ControlledVocabulary.transaction do
      sizes.each do |s|
        ControlledVocabulary.where(model_type: "Video", model_attribute: ':size', value: s, active_status: true).delete_all
      end
      %w(NTSC PAL SECAM Other).each do |s|
        ControlledVocabulary.where(model_type: "Video", model_attribute: ':recording_standard', value: s, active_status: true).delete_all
      end
      %w(10 15 20 30 60 90 100 120 cartridge).each do |s|
        ControlledVocabulary.where(model_type: "Video", model_attribute: ':maximum_runtime', value: s, active_status: true).delete_all
      end
      %w(acetate polyester mixed other).each do |s|
        ControlledVocabulary.where(model_type: "Video", model_attribute: ':base', value: s, active_status: true).delete_all
      end
      %w(Ampex Fuji Maxell Panasonic Quantegy Scotch Sony other).each do |s|
        ControlledVocabulary.where(model_type: "Video", model_attribute: ':stock', value: s, active_status: true).delete_all
      end
      %w(Standard\ Play Long\ Play Extended\ Play Other).each do |s|
        ControlledVocabulary.where(model_type: "Video", model_attribute: ':playback_speed', value: s, active_status: true).delete_all
      end
      %w(Yes\ (isolate\ in\ mold\ bin) No Treated).each do |s|
        ControlledVocabulary.where(model_type: "Video", model_attribute: ':mold', value: s, active_status: true).delete_all
      end

      # rated conditions
      [ "Pack Deformation", "Water Damage", "Warp", "Splice Damage", "Dirty", "Label Damage", "Peeling", "Delamination",
        "Scratches", "Creasing", "Tape Residue", "Broken"].each do |s|
        ControlledVocabulary.where(model_type: "Video", model_attribute: ':value_condition', value: s, active_status: true).delete_all
      end
      # rated condition ratings
      ["1 - Minimal", "2 - Moderate", "3 - Heavy", "4 - Possibly Unplayable", "5 - Deaccession"].each do |s|
        ControlledVocabulary.where(model_type: "Video", model_attribute: ':rated_condition_rating', value: s, active_status: true).delete_all
      end

      # boolean conditions
      ["Soft Binder Syndrome / Sticky Shed Syndrome", "Poor Wind"].each do |s|
        ControlledVocabulary.where(model_type: "Video", model_attribute: ':boolean_condition', value: s, active_status: true).delete_all
      end

      # overall condition ratings
      ["1 - Excellent","2 - Minimal","3 - Moderate","4 - Heavy","5 - Possibly Unplayable","6 - Deaccession"].each do |s|
        ControlledVocabulary.where(model_type: "Video", model_attribute: ':overall_condition_rating', value: s, active_status: true).delete_all
      end

      # research value rating
      ["1 - High","2 - Medium","3 - Low"].each do |s|
        ControlledVocabulary.where(model_type: "Video", model_attribute: ':research_value', value: s, active_status: true).delete_all
      end
    end
  end
end
