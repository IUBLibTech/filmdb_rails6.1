class AddNewCv < ActiveRecord::Migration[4.2]
  ControlledVocabulary.transaction do
    @creator_role = %w(Adapted\ by Assistant\ Artistic\ Director Assistant\ Director Assistant\ Producer Continuity Grip Music\ Performer Production\ Assistant Production\ Company Production\ Manager Prop\ Master Researcher Special\ Effects Translated\ by Unit\ Manager With\ the\ Cooperation\ of)

    @creator_role.each do |cv|
      ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_creator_role_type', value: cv).save
    end
    ControlledVocabulary.new(model_type: 'Title', model_attribute: ':title_publisher_role_type', value: 'With the Cooperation of').save
    ControlledVocabulary.new(model_type: 'TitleGenre', model_attribute: ':genre', value: 'Drama').save
    ControlledVocabulary.new(model_type: 'TitleDate', model_attribute: ':date_type', value: 'Release Date').save
  end
end
