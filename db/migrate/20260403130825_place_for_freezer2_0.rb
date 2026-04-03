class PlaceForFreezer20 < ActiveRecord::Migration[8.0]
  OLD_VAL = "2.0"
  NEW_VAL = "2.0 (place for freezer)"
  def up
    ControlledVocabulary.where(model_type: "Film", model_attribute: ":ad_strip", value: OLD_VAL).update(value: NEW_VAL)
    # update all films with ad_strip 2.0 to the new vocab
    Film.where(ad_strip: OLD_VAL).update(ad_strip: NEW_VAL)
  end

  def down
    ControlledVocabulary.where(model_type: "Film", model_attribute: ":ad_strip", value: NEW_VAL).update(value: OLD_VAL)
    # update all films with ad_strip 2.0 to the new vocab
    Film.where(ad_strip: NEW_VAL).update(ad_strip: OLD_VAL)
  end
end
