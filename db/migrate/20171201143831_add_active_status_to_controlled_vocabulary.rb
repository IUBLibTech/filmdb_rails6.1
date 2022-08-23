class AddActiveStatusToControlledVocabulary < ActiveRecord::Migration[4.2]
  def change
    # flag for disabling controlled vocabulary
    add_column :controlled_vocabularies, :active_status, :boolean, default: true
    # remove the a_unused PhysicalObject :access attribute
    ControlledVocabulary.where(model_type: 'PhysicalObject', model_attribute: ':access').delete_all

    # deactivate these component group types - they are not currently in use
    inactive = [
      "Exhibition", "Original Distribution", "Pre-Production Elements", "Preservation Elements", "Reference",
      "Reformatting", "Reformatting Replacement (MDPI)", "Teaching", "Training & Tours", 'Best Copy'
    ]
    ControlledVocabulary.where(value: inactive).update_all(active_status: false)

    # change the order in whch component group types are presented in menues
    order = ['Reformatting (MDPI)', 'Best Copy (MDPI)', 'Best Copy (MDPI - WELLS)']
    order.each_with_index do |o, i|
      ControlledVocabulary.where(model_type: 'ComponentGroup', value: o).first.update(menu_index: i)
    end
  end
end
