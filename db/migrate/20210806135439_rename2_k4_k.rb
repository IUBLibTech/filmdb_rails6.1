class Rename2K4K < ActiveRecord::Migration[4.2]
  def up
    if WorkflowStatus::TWO_K_FOUR_K_SHELVES == "2k/4k Shelves (ALF)"
      raise "Cannot continue migration - Best copy constants must be changed in WorkflowStatus.rb first"
      puts "############################################################################"
      puts "                            IMPORTANT!!!"
      puts "                            IMPORTANT!!!"
      puts "                            IMPORTANT!!!"
      puts "       Make sure to modify WorkflowStatus.rb to change"
      puts "       the TWO_K_FOUR_K_SHELVES constant to its NEW value BEFORE"
      puts "       running this migration."
      puts "       WorkflowStatus::TWO_K_FOUR_K_SHELVES 'Digitization Shelf'"
      puts "############################################################################"
    else
      WorkflowStatus.where(status_name: "2k/4k Shelves (ALF)").update_all(status_name: WorkflowStatus::TWO_K_FOUR_K_SHELVES)
    end
  end
  def down
    WorkflowStatus.where(status_name: WorkflowStatus::TWO_K_FOUR_K_SHELVES).update_all(status_name: "2k/4k Shelves (ALF)")
    if WorkflowStatus::TWO_K_FOUR_K_SHELVES == "Digitization Shelf"
      puts "############################################################################"
      puts "                            IMPORTANT!!!"
      puts "                            IMPORTANT!!!"
      puts "                            IMPORTANT!!!"
      puts ""
      puts "                  You have rolled back a migration"
      puts ""
      puts "       Make sure to modify WorkflowStatus.rb to change"
      puts "       the TWO_K_FOUR_K_SHELVES constant to its OLD value AFTER"
      puts "       running this migration."
      puts "       WorkflowStatus::TWO_K_FOUR_K_SHELVES '2k/4k Shelves (ALF)'"
      puts "############################################################################"
    end
  end
end
