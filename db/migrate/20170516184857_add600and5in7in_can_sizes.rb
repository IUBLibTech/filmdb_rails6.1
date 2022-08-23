class Add600and5in7inCanSizes < ActiveRecord::Migration[4.2]
  def up
    ControlledVocabulary.where('model_attribute = ":can_size" AND menu_index > 4').each do |cv|
      cv.update(menu_index: (cv.menu_index + 1))
    end
    ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: '600', menu_index: 5).save
    ['5 inch box', '7 in box'].each_with_index do |s, i|
      ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ':can_size', value: s, menu_index: 14 + i).save
    end
  end

  def down
    ControlledVocabulary.where('model_attribute = ":can_size" AND menu_index > 13').delete_all
    ControlledVocabulary.where('model_attribute = ":can_size" AND value = "600"').delete_all
    ControlledVocabulary.where('model_attribute = ":can_size" AND menu_index > 5').each do |cv|
      cv.update(menu_index: (cv.menu_index - 1))
    end
  end
end
