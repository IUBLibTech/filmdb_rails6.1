class RenameSoundTrackToSoundtrack < ActiveRecord::Migration[4.2]
  def up
    ControlledVocabulary.where(value: 'Sound Track Damage').first.update(value: 'Soundtrack Damage')
  end

  def down
    ControlledVocabulary.where(value: 'Soundtrack Damage').first.update(value: 'Sound Track Damage')
  end
end
