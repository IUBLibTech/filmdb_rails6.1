class AddTrackConfigurationToRecordedSound < ActiveRecord::Migration[4.2]
  VALS = ["Full Track", "Half Track", "Quarter Track", "Unknown"]
  def up
    VALS.each do |v|
      unless ControlledVocabulary.where(model_type: "RecordedSound", model_attribute: ":track_configuration", value: v).size > 0
        ControlledVocabulary.new(model_type: "RecordedSound", model_attribute: ":track_configuration", value: v).save
      end
    end
    unless column_exists? :recorded_sounds, :track_configuration
      add_column :recorded_sounds, :track_configuration, :string
    end
  end
  def down
    ControlledVocabulary.where(model_type: "Recorded Sound", model_attribute: ":track_configuration").delete_all
    if column_exists? :recorded_sounds, :track_configuration
      remove_column :recorded_sounds, :track_configuration
    end
  end
end
