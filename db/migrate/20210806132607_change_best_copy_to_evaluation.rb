class ChangeBestCopyToEvaluation < ActiveRecord::Migration[4.2]
  def up
    if WorkflowStatus::BEST_COPY_ALF == "Best Copy (ALF)" || WorkflowStatus::BEST_COPY_WELLS == "Best Copy (Wells)" ||
      WorkflowStatus::BEST_COPY_MDPI_WELLS == "Best Copy (MDPI - Wells)"
      puts "############################################################################"
      puts "                            IMPORTANT!!!"
      puts "                            IMPORTANT!!!"
      puts "                            IMPORTANT!!!"
      puts "       Make sure to modify WorkflowStatus.rb to change"
      puts "       the BEST_COPY_* constants to their NEW values BEFORE"
      puts "       running this migration."
      puts "       WorkflowStatus::BEST_COPY_ALF becomes 'Evaluation (Alf)'"
      puts "       WorkflowStatus::BEST_COPY_WELLS becomes 'Evaluation (Wells)'"
      puts "       WorkflowStatus::BEST_COPY_MDPI_WELLS becomes 'Evaluation (Wells)'"
      puts "       Yes, the last two are the same value."
      puts "############################################################################"
      raise "Cannot continue migration - Best copy constants must be changed in WorkflowStatus.rb first"
    else
      WorkflowStatus.where(status_name: "Best Copy (ALF)").update_all(status_name: WorkflowStatus::BEST_COPY_ALF)
      WorkflowStatus.where(status_name: "Best Copy (Wells)").update_all(status_name: WorkflowStatus::BEST_COPY_WELLS)
      WorkflowStatus.where(status_name: "Best Copy (MDPI - Wells)").update_all(status_name: WorkflowStatus::BEST_COPY_WELLS)
    end
  end

  def down
    WorkflowStatus.where(status_name:  WorkflowStatus::BEST_COPY_ALF).update_all(status_name: "Best Copy (ALF)")
    # there currently were no items with Best Copy (Wells) workflow history so everything
    WorkflowStatus.where(status_name: WorkflowStatus::BEST_COPY_WELLS).update_all(status_name: "Best Copy (MDPI - Wells")
    puts "############################################################################"
    puts "                            IMPORTANT!!!"
    puts "                            IMPORTANT!!!"
    puts "                            IMPORTANT!!!"
    puts ""
    puts "       You have rolled back a migration"
    puts ""
    puts "       Make sure to modify WorkflowStatus.rb to change"
    puts "       the BEST_COPY_* constants back to their ORIGINAL values AFTER"
    puts "       running this migration."
    puts "       WorkflowStatus::BEST_COPY_ALF becomes 'Best Copy (Alf)'"
    puts "       WorkflowStatus::BEST_COPY_WELLS becomes 'Best Copy (Wells)'"
    puts "       WorkflowStatus::BEST_COPY_MDPI_WELLS becomes 'Best Copy (MDPI - Wells)'"
    puts "############################################################################"
  end
end
