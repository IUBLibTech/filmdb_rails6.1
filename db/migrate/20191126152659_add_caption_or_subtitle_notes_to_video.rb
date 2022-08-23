class AddCaptionOrSubtitleNotesToVideo < ActiveRecord::Migration[4.2]
  def up
    rename_column :videos, :caption_or_subtitles, :captions_or_subtitles
    add_column :videos, :captions_or_subtitles_notes, :text unless column_exists? :videos, :captions_or_subtitles_notes
    add_column :videos, :generation_notes, :text unless column_exists? :videos, :generation_notes
    add_column :videos, :sound, :string unless column_exists? :videos, :sound
    %w(Sound Silent).each_with_index do |v, i|
      ControlledVocabulary.new(model_type: 'Video', model_attribute: ':sound', value: v, menu_index: i).save!
    end
  end

  def down
    remove_column :videos, :captions_or_subtitles_notes, :text if column_exists? :videos, :captions_or_subtitles_notes
    remove_column :videos, :generation_notes, :text if column_exists? :videos, :generation_notes
    remove_column :videos, :sound, :string if column_exists? :videos, :sound
    ControlledVocabulary.where(model_type: 'Video', model_attribute: ':sound').delete_all
  end
end
