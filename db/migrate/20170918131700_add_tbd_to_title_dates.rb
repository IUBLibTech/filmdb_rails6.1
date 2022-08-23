class AddTbdToTitleDates < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.new(model_type: 'TitleDate', model_attribute: ':date_type', value: 'TBD').save!
  end
end
