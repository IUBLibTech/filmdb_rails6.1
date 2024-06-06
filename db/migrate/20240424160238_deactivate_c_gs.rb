class DeactivateCGs < ActiveRecord::Migration[6.1]
  def up
    ControlledVocabulary.where(model_type: "ComponentGroup", model_attribute: ":group_type", value: ["Reformatting (MDPI)", "Best Copy (MDPI)", "Best Copy (MDPI - WELLS)"]).update_all(
      active_status: false
    )
  end

  def down
    ControlledVocabulary.where(model_type: "ComponentGroup", model_attribute: ":group_type", value: ["Reformatting (MDPI)", "Best Copy (MDPI)", "Best Copy (MDPI - WELLS)"]).update_all(
      active_status: true
    )
  end
end
