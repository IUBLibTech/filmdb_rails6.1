class CorrectMispelledBroadcast < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.where(value: "Braodcast Engineer").update_all(value: "Broadcast Engineer")
  end
end
