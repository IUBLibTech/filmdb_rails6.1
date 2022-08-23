class AddEquipmentTechnologyControlledVocabulary < ActiveRecord::Migration[4.2]
  def up
    conditions = ['1 - Excellent', '2 - Minimal', '3 - Moderate', '4 - Heavy', '5 - Possibly Unplayable', '6 - Deaccession']
    conditions.each do |c|
      ControlledVocabulary.new(model_type: 'Equipment/Technology', model_attribute: ':overall_condition_rating', value: c ).save
    end
    research_vals = ['1 - High', '2 - Medium', '3 - Low']
    research_vals.each do |r|
      ControlledVocabulary.new(model_type: 'Equipment/Technology', model_attribute: ':research_value', value: r ).save
    end
    working_conditions = ['Functioning', 'Partially Functioning', 'Not Functioning - Needs Repair', 'Not Functioning - Unable to Repair', 'Not Tested']
    working_conditions.each do |w|
      ControlledVocabulary.new(model_type: 'Equipment/Technology', model_attribute: ':working_condition', value: w ).save
    end
  end

  def down
    ControlledVocabulary.where(model_type: 'Equipment/Technology').delete_all
  end
end
