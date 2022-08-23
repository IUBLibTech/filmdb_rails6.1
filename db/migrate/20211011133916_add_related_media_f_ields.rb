class AddRelatedMediaFIelds < ActiveRecord::Migration[4.2]
  FILM_GAUGES = ControlledVocabulary.where(model_type: 'Film', model_attribute: ':gauge')
  VIDEO_GAUGES = ControlledVocabulary.where(model_type: 'Video', model_attribute: ':gauge')
  RECORDED_SOUND_GAUGES = ControlledVocabulary.where(model_type: 'RecordedSound', model_attribute: ':gauge')
  def up
    FILM_GAUGES.each do |g|
      val = "film_gauge_#{g.value.downcase.parameterize.underscore}"
      unless EquipmentTechnology.column_names.include? val
        add_column :equipment_technologies, val.to_sym, :boolean
      end
    end
    VIDEO_GAUGES.each do |g|
      val = "video_gauge_#{g.value.downcase.parameterize.underscore}"
      unless EquipmentTechnology.column_names.include? val
        add_column :equipment_technologies, val.to_sym, :boolean
      end
    end
    RECORDED_SOUND_GAUGES.each do |g|
      val = "recorded_sound_gauge_#{g.value.downcase.parameterize.underscore}"
      unless EquipmentTechnology.column_names.include? val
        add_column :equipment_technologies, val.to_sym, :boolean
      end
    end

  end
  def down
    FILM_GAUGES.each do |g|
      val = "film_gauge_#{g.value.downcase.parameterize.underscore}"
      if EquipmentTechnology.column_names.include? val
        remove_column :equipment_technologies, val.to_sym
      end
    end
    VIDEO_GAUGES.each do |g|
      val = "video_gauge_#{g.value.downcase.parameterize.underscore}"
      if EquipmentTechnology.column_names.include? val
        remove_column :equipment_technologies, val.to_sym
      end
    end
    RECORDED_SOUND_GAUGES.each do |g|
      val = "recorded_sound_gauge_#{g.value.downcase.parameterize.underscore}"
      if EquipmentTechnology.column_names.include? val
        remove_column :equipment_technologies, val.to_sym
      end
    end


  end


end
