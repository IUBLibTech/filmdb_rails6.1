class AddRecordedSoundControlledVocab < ActiveRecord::Migration[4.2]
  BASES = ['Acetate', 'Aluminum', 'Cardboard', 'Glass', 'Plaster', 'Polyester', 'Shellac', 'Steel', 'Vinyl', 'Wax']
  GAUGES = ['Open reel audiotape', 'Grooved analog disc', '1 inch audio tape', '1/2 inch audio cassette', '1/4 inch audio cassette',
            '1/4 inch audio tape', '2 inch audio tape', '8-track', 'Aluminum disc', 'Audio cassette', 'Audio CD', 'DAT',
            'DDS', 'DTRS', 'Flexi Disc', 'Grooved Dictabelt', 'Lacquer disc', 'Magnetic Dictabelt', 'Mini-cassette',
            'PCM Betamax', 'PCM U-matic', 'PCM VHS', 'Piano roll', 'Plastic cylinder', 'Shellac disc',  'Super Audio CD',
             'Vinyl recording', 'Wax cylinder', 'Wire recording'
  ]
  MOLD = ['Yes (isolated in mold bin)', 'No', 'Treated']
  OA_CONDITIONS = ['1 - Excellent', '2 - Minimal', '3 - Moderate', '4 - Heavy', '5 - Possibly Unplayable']
  CONDITIONS = ["Broken", "Chips", "Cracks", "Crazing", "Creasing", "Digs", "Dirty", "Delamination or flaking",
                "Exudation", "Label damage", "Missing pieces", "Miscellaneous", "Needle run", "Oxidation", "Peeling",
                 "Scratches", "Tape residue", "Water damage", "Warp", "Wear"]
  PLAYBACKS = ['0.46875 ips', '0.9375 ips', '1.875 ips', '3.75 ips', '7.5 ips', '15 ips', '30 ips', '16 rpm', '33 1/3 rpm',
               '45 rpm', '78 rpm', '120 rpm', '160 rpm', 'Unknown']
  RESEARCH_VALS = ['1 - High', '2 - Medium', '3 - Low']
  SIDES = ["1", "2"]
  SIZES = ['4 inch Standard Cylinder', '4 inch Concert Cylinder', '6 inch Cylinder', '5 inch Disc', '7 inch Disc',
           '8 inch Disc', '10 inch Disc', '12 inch Disc', '16 inch Disc', '18 inch Disc', '3.5 inch Dictabelt',
           '3 inch Reel', '4 inch Reel', '5 inch Reel', '6 inch Reel', '7 inch Reel', '10 inch Reel', '10.5 inch Reel'
  ]
  STOCKS = ['Busy Bee', 'Columbia', 'Edison - Amberol', 'Edison - Gold Moulded', 'Edison Bell', 'Indestructible',
            'Lambert', 'Pathe', 'Presto', 'Sterling', 'US Everlasting', 'Other'
  ]

  def up
    ControlledVocabulary.transaction do
      BASES.each do |b|
        ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':base', value: b).save!
      end
      GAUGES.each do |g|
        ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':gauge', value: g).save!
      end
      MOLD.each do |m|
        ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':mold', value: m).save!
      end
      OA_CONDITIONS.each do |c|
        ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':overall_condition_rating', value: c).save!
      end
      CONDITIONS.each do |c|
        ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':value_condition', value: c).save!
      end
      # only 2 boolean conditions for Recorded Sound
      ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':boolean_condition', value: 'Broken').save!
      ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':boolean_condition', value: 'Missing Pieces').save!


      PLAYBACKS.each do |s|
        ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':playback_speed', value: s).save!
      end

      rated_conditions = OA_CONDITIONS
      rated_conditions.each do |rc|
        ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':rated_condition', value: rc).save!
      end
      RESEARCH_VALS.each do |rv|
        ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':research_value', value: rv).save!
      end
      SIDES.each do |s|
        ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':sides', value: s).save!
      end
      SIZES.each do |s|
        ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':size', value: s).save!
      end
      STOCKS.each do |s|
        ControlledVocabulary.new(model_type: 'RecordedSound', model_attribute: ':stock', value: s).save!
      end
    end
  end

  def down
    ControlledVocabulary.where(model_type: 'RecordedSound').delete_all
  end
end
