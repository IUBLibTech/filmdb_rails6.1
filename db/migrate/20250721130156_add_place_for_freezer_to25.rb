class AddPlaceForFreezerTo25 < ActiveRecord::Migration[8.0]
  OLD_ONE = "2.5"
  NEW_ONE = "2.5 (place for freezer)"

  def up
    # make sure code for Film#place_in_freezer? works with the new value
    if Film::PLACE_IN_FREEZER_VALS.include?(OLD_ONE)
      raise "You need to modify Film::PLACE_FOR_FREEZER_VALS by removing #{OLD_ONE} and including #{NEW_ONE} before you can run this migration!"
    end
    Film.where(ad_strip: OLD_ONE).update_all(ad_strip: NEW_ONE)
    ControlledVocabulary.where(model_type: Film, model_attribute: ":ad_strip", value: OLD_ONE).update(value: NEW_ONE)
  end

  def down
    # make sure code for Film#place_in_freezer? has been reverted to work with the OLD value
    if Film::PLACE_IN_FREEZER_VALS.include?(NEW_ONE)
      raise "You need to modify Film::PLACE_IN_FREEZER_VALS by removing #{NEW_ONE} and including #{OLD_ONE} before you can revert this migration!"
    end
    Film.where(ad_strip: NEW_ONE).update_all(ad_strip: OLD_ONE)
    ControlledVocabulary.where(model_type: Film, model_attribute: ":ad_strip", value: NEW_ONE).update(value: OLD_ONE)
  end
end
