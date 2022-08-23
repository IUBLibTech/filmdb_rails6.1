class AddVideoGaugeControlledVocabulary < ActiveRecord::Migration[4.2]
  BAD_CV = %w(ALF\ -\ Formally\ Ingested ALF\ -\ Unprocessed ALF\ -\ Freezer ALF\ -\ Awaiting\ Freezer Wells\ 052 Memnon IU\ Cinema)
  GAUGES = %w(1\ inch\ videotape 1/2\ inch\ videotape 1/4\ inch\ videotape 2\ inch\ videotape Betacam Betacam\ SP Betacam\ SX Betamax Blu-ray\ disc Cartrivision D1 D2 D3 D5 D6 D9 DCT Digital\ Betacam Digital8 DV DVCAM DVCPRO DVD EIAJ\ Cartridge EVD\ Videodisc HDCAM Hi8 LaserDisc MII MiniDV HDV Super\ Video\ CD U-matic Universal\ Media\ Disc V-Cord VHS VHS-C SVHS Video8\ aka\ 8mm\ video VX Videocassette Open\ reel\ videotape Optical\ video\ disc other)
  def up
    # need to eliminate some old ControlledVocabulary for PhysicalObjects that was supplanted by WorkflowStatuses
    ControlledVocabulary.where(model_type: "PhysicalObject", model_attribute: ':location').delete_all
    ControlledVocabulary.transaction do
      GAUGES.each do |g|
        ControlledVocabulary.new(model_type: 'Video', model_attribute: ":gauge", value: g).save!
      end
    end
  end

  def down
    ControlledVocabulary.where(model_type: 'Video', model_attribute: ':gauge').delete_all
    ControlledVocabulary.transaction do
      BAD_CV.each do |cv|
        ControlledVocabulary.new(model_type: 'PhysicalObject', model_attribute: ":location", value: cv).save!
      end
      ControlledVocabulary.where(model_type: "Video", model_attribute: ':gauge').delete_all
    end
  end
end
