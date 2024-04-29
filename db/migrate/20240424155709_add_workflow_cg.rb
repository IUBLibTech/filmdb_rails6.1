class AddWorkflowCg < ActiveRecord::Migration[6.1]
  def change
    unless ControlledVocabulary.where(model_type: "ComponentGroup", model_attribute: ":group_type", value: "Workflow").exists?
      ControlledVocabulary.new(model_type: "ComponentGroup", model_attribute: ":group_type", value: "Workflow", active_status: true, menu_index: 0).save!
    end
  end
end
