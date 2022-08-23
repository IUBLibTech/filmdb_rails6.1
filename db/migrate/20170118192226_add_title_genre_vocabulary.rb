class AddTitleGenreVocabulary < ActiveRecord::Migration[4.2]
  def up
    vals = [ 'Actuality', 'Adaptation', 'Adventure', 'Adventure (Nonfiction)', 'Ancient world', 'Animal', 'Art', 'Aviation',
        'Biographical', 'Biographical (Nonfiction)', 'Buddy', 'Caper', 'Chase', 'Children\'s', 'College', 'Comedy', 'Crime',
        'Dance', 'Dark comedy', 'Disability', 'Disaster', 'Documentary', 'Domestic comedy', 'Educational', 'Erotic', 'Espionage',
        'Ethnic', 'Ethnic (Nonfiction)', 'Ethnographic', 'Experimental', 'Experimental - Absolute', 'Experimental - Abstract live action',
        'Experimental - Activist', 'Experimental - Autobiographical', 'Experimental - City symphony', 'Experimental - Cubist',
        'Experimental - Dada', 'Experimental - Diary', 'Experimental - Feminist', 'Experimental - Gay/lesbian', 'Experimental - Intermittent animation',
        'Experimental - Landscape', 'Experimental - Loop', 'Experimental - Lyrical', 'Experimental - Participatory', 'Experimental - Portrait',
        'Experimental - Reflexive', 'Experimental - Street', 'Experimental - Structural', 'Experimental - Surrealist', 'Experimental - Text',
        'Experimental - Trance', 'Exploitation', 'Fallen woman', 'Family', 'Fantasy', 'film noir', 'Game', 'Gangster', 'Historical',
        'Home shopping', 'Horror', 'Industrial', 'Instructional', 'Interview', 'Journalism', 'Jungle', 'Juvenile delinquency',
        'Lecture', 'Legal', 'Magazine', 'Martial arts', 'Maternal melodrama', 'Medical', 'Medical (Nonfiction)', 'Melodrama',
        'Military', 'Music', 'Music video', 'Musical', 'Mystery', 'Nature', 'News', 'Newsreel', 'Opera', 'Operetta', 'Parody',
        'Police', 'Political', 'Pornography', 'Prehistoric', 'Prison', 'Propaganda', 'Public access', 'Public affairs', 'Reality-based',
        'Religion', 'Religious', 'Road', 'Romance', 'Science fiction', 'Screwball comedy', 'Show business', 'Singing cowboy',
        'Situation comedy', 'Slapstick comedy', 'Slasher', 'Soap opera', 'Social guidance', 'Social problem', 'Sophisticated comedy',
        'Speculation', 'Sponsored', 'Sports', 'Sports (Nonfiction)', 'Survival', 'Talk', 'Thriller', 'Training', 'Travelogue',
        'Trick', 'Trigger', 'Variety', 'War', 'War (Nonfiction)', 'Western', 'Women', 'Youth', 'Yukon']
    vals.each_with_index do |v, i|
      ControlledVocabulary.new(model_type: 'TitleGenre', model_attribute: ':genre', value: v, index: i).save
    end
  end

  def down
    ControlledVocabulary.where(model_type: 'TitleGenre').delete_all
  end
end
