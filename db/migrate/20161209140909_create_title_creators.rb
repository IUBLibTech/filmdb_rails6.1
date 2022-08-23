class CreateTitleCreators < ActiveRecord::Migration[4.2]
  def up
    create_table :title_creators do |t|
      t.integer :title_id, limit: 8
      t.string :name
      t.string :role
      t.timestamps null: false
    end
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Actor', default: nil, index: 1).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Artist', default: nil, index: 2).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Associate Producer', default: nil, index: 3).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Author', default: nil, index: 4).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Camera Operator', default: nil, index: 5).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Caption Writer', default: nil, index: 6).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Casting Director', default: nil, index: 7).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Cinematographer', default: nil, index: 8).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Co-producer', default: nil, index: 9).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Commentator', default: nil, index: 10).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Composer', default: nil, index: 11).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Concept Artist', default: nil, index: 12).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Conductor', default: nil, index: 13).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Describer', default: nil, index: 14).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Director', default: nil, index: 15).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Artistic Director', default: nil, index: 16).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Choreographer', default: nil, index: 17).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Direction of Photography', default: nil, index: 18).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Editor', default: nil, index: 19).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Graphic Editor', default: nil, index: 20).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Executive Producer', default: nil, index: 21).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Filmmaker', default: nil, index: 22).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Graphic Designer', default: nil, index: 23).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Guest', default: nil, index: 24).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Host', default: nil, index: 25).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Interviewee', default: nil, index: 26).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Interviewer', default: nil, index: 27).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Lighting Technician', default: nil, index: 28).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Make-Up Artist', default: nil, index: 29).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Moderator', default: nil, index: 30).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Music Supervisor', default: nil, index: 31).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Narrator', default: nil, index: 32).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Panelist', default: nil, index: 33).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Performer', default: nil, index: 34).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Performing Group', default: nil, index: 35).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Photographer', default: nil, index: 36).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Producer', default: nil, index: 37).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Production Unit', default: nil, index: 38).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Foley Artist', default: nil, index: 39).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Sound Designer', default: nil, index: 40).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Sound Editor', default: nil, index: 41).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Recording Engineer', default: nil, index: 42).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Voiceover Artist', default: nil, index: 43).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Reporter', default: nil, index: 44).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Set Designer', default: nil, index: 45).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Braodcast Engineer', default: nil, index: 46).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Speaker', default: nil, index: 47).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Technical Director', default: nil, index: 48).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Video Engineer', default: nil, index: 49).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Vocalist', default: nil, index: 50).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Costume Designer', default: nil, index: 51).save
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: 'Writer', default: nil, index: 52).save
  end

  def down
    drop_table :title_creators
    ControlledVocabulary.where(model_type: 'Title', model_attribute: ':title_creator_role_type').delete_all
  end
end
