class AddTitleDateTypeVocabulary < ActiveRecord::Migration[4.2]
  def up
    vals = [
        'Distribution Date', 'Broadcast Date', 'Recording Date', 'Reissue Date', 'Copyright Date', 'Publication Date',
        'Content Date', 'Unknown'
    ]
    vals.each_with_index do |v, i|
      ControlledVocabulary.new(model_type: 'TitleDate', model_attribute: ':date_type', value: v, index: i).save
    end

  end

  def down
    ControlledVocabulary.where(model_type: 'TitleDate').destroy_all
  end
end
