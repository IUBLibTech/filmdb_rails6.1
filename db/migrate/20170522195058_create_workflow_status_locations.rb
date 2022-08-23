class CreateWorkflowStatusLocations < ActiveRecord::Migration[4.2]
  def change
    create_table :workflow_status_locations do |t|
      t.string :location_type
      t.string :facility
      t.string :physical_location
      t.text :notes
      t.timestamps
    end

    # removed to get migration to work after removing WorkflowStatusLocation and WorkflowStatusTemplate models
    # [
    #   [:in_storage, 'ALF', ''],
    #
    #   [:shipped_external, 'Memnon', ''], [:shipped_external, 'Library of Congress'], [:shipped_external, 'Museum of Modern Art'],
    #
    #   [:on_site, 'IULMIA-Wells', 'Best Copy'], [:on_site, 'IULMIA-Wells', 'In Freezer'], [:on_site, 'IULMIA-Wells', 'Sent for Mold Abatement'],
    #   [:on_site, 'IULMIA-Wells', 'Packed for Shipping'], [:on_site, 'IULMIA-ALF', 'In Freezer'], [:on_site, 'IULMIA-ALF', 'Digitization Prep'],
    #   [:on_site, 'IULMIA-ALF', 'Packed in Cage'], [:on_site, 'IULMIA-Wells', 'Just Inventoried', 'Items start at this location immediately after inventory']
    # ].each do |l|
    #   notes = ''
    #   if l.size > 3
    #     notes = l[3]
    #   end
    #   WorkflowStatusLocation.new(location_type: l[0].to_s, facility: l[1], physical_location: l[2], notes: notes).save
    # end
  end
end
