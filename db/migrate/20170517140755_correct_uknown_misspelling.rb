class CorrectUknownMisspelling < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.where(value: 'Uknown').update_all(value: 'Unknown')
  end
end
