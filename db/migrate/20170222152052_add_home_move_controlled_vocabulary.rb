class AddHomeMoveControlledVocabulary < ActiveRecord::Migration[4.2]
  def up
    # need to adjust the index by one so that Home movie will be inserted in that order properly
    ControlledVocabulary.where("model_type = 'TitleForm' AND model_attribute = ':form' AND controlled_vocabularies.index > 22").each do |cv|
      cv.index += 1
      cv.save
    end
    ControlledVocabulary.new(model_type: 'TitleForm', model_attribute: ':form', value: 'Home movie', index: 23).save
  end

  def down
    ControlledVocabulary.where(model_type: 'TitleForm', model_attribute: ':form', value: 'Home movie').delete_all
    ControlledVocabulary.where("model_type = 'TitleForm' AND model_attribute = ':form' AND controlled_vocabularies.index > 23").each do |cv|
      cv.index -= 1
      cv.save
    end
  end
end
