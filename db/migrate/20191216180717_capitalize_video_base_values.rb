class CapitalizeVideoBaseValues < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.where(model_type: 'Video', model_attribute: ':base').each do |cv|
      cv.update(value: cv.value.capitalize)
    end
    Video.where("base is not null").each do |v|
      v.update(base: v.base.capitalize)
    end
  end
end
