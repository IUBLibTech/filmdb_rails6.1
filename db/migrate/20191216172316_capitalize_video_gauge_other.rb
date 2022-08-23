class CapitalizeVideoGaugeOther < ActiveRecord::Migration[4.2]

  def up
    ControlledVocabulary.where(model_type: 'Video', model_attribute: ':gauge', value: 'other').update_all(value: 'Other')
    Video.where(gauge: 'other').update_all(gauge: 'Other')
  end

  def down
    ControlledVocabulary.where(model_type: 'Video', model_attribute: ':gauge', value: 'Other').update_all(value: 'other')
    Video.where(gauge: 'Other').update_all(gauge: 'other')
  end

end
