class ChangeTapeResidueToAdhesiveResidue < ActiveRecord::Migration[6.1]
  def up
    ControlledVocabulary.where(value: "Tape Residue").update_all(value: 'Adhesive Residue')
  end

  def down
    ControlledVocabulary.where(value: "Adhesive Residue").update_all(value: 'Tape Residue')
  end
end
