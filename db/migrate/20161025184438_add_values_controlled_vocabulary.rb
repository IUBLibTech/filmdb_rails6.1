class AddValuesControlledVocabulary < ActiveRecord::Migration[4.2]
  def up
    # access CV
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':access', value: 'Exhibition', default: false, index: 1).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':access', value: 'Reference', default: false, index: 2).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':access', value: 'Restricted', default: false, index: 3).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':access', value: 'Deaccessioned', default: false, index: 4).save

    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':location', value: 'ALF - Formally Ingested', default: false, index: 1).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':location', value: 'ALF - Unprocessed', default: false, index: 2).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':location', value: 'ALF - Freezer', default: false, index: 3).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':location', value: 'ALF - Awaiting Freezer', default: false, index: 4).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':location', value: 'Wells 052', default: false, index: 5).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':location', value: 'Memnon', default: false, index: 6).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':location', value: 'IU Cinema', default: false, index: 7).save

    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':gauge', value: '8mm', default: false, index: 1).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':gauge', value: 'Super 8mm', default: false, index: 2).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':gauge', value: '9.5mm', default: false, index: 3).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':gauge', value: '16mm', default: false, index: 4).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':gauge', value: 'Super 16mm', default: false, index: 5).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':gauge', value: '28mm', default: false, index: 6).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':gauge', value: '35mm', default: false, index: 7).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':gauge', value: '35/32mm', default: false, index: 8).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':gauge', value: '70mm', default: false, index: 9).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':gauge', value: 'Other', default: false, index: 10).save

    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: '50', default: false, index: 1).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: '100', default: false, index: 2).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: '200', default: false, index: 3).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: '400', default: false, index: 4).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: '800', default: false, index: 5).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: '1000', default: false, index: 6).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: '1200', default: false, index: 7).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: '1600', default: false, index: 8).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: '1800', default: false, index: 9).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: '2000', default: false, index: 10).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: '3000', default: false, index: 11).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: 'Cartidge', default: false, index: 12).save

    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':frame_rate', value: '16 fps', default: false, index: 1).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':frame_rate', value: '18 fps', default: false, index: 2).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':frame_rate', value: '24 fps', default: false, index: 3).save

    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':ad_strip', value: '0.0', default: false, index: 1).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':ad_strip', value: '0.5', default: false, index: 2).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':ad_strip', value: '1.0', default: false, index: 3).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':ad_strip', value: '1.5', default: false, index: 4).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':ad_strip', value: '2.0', default: false, index: 5).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':ad_strip', value: '2.5', default: false, index: 6).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':ad_strip', value: '3.0 (place for freezer)', default: false, index: 7).save

    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':mold', value: 'Yes (isolate in mold bin)', default: false, index: 1).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':mold', value: 'No', default: false, index: 2).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':mold', value: 'Treated', default: false, index: 3).save

    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':condition_type', value: '1 - Minimal', default: false, index: 1).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':condition_type', value: '2 - Moderate', default: false, index: 2).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':condition_type', value: '3 - Heavy', default: false, index: 3).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':condition_type', value: '4 - Possibly Unplayable', default: false, index: 4).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':condition_type', value: '5 - Deaccessioned', default: false, index: 5).save

    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':condition_rating', value: '1 - Excellent', default: false, index: 1).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':condition_rating', value: '2 - Minimal', default: false, index: 2).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':condition_rating', value: '3 - Moderate', default: false, index: 3).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':condition_rating', value: '4 - Heavy', default: false, index: 4).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':condition_rating', value: '5 - Possibly Unplayable', default: false, index: 5).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':condition_rating', value: '6 - Deaccessioned', default: false, index: 6).save

    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':research_value', value: '1 - High', default: false, index: 1).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':research_value', value: '2 - Medium', default: false, index: 2).save
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':research_value', value: '3 - Low', default: false, index: 3).save



  end
end
