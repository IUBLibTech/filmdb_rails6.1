class ChangeDigiPrepTo2k4k < ActiveRecord::Migration[4.2]
  def change
    # removed to get migration to work after removing WorkflowStatusLocation and WorkflowStatusTemplate models
    # WorkflowStatusLocation.where(physical_location: 'Digitization Prep').update_all(physical_location: '2k/4k Shelves')
  end
end
