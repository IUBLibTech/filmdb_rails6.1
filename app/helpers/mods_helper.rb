module ModsHelper
  # maps Filmdb PhysicalObject media_type values to MODS typeOfResource values
  MEDIA_TYPE_MAP = {
      "Moving Image": "moving image", "Recorded Sound": "sound recording", "Still Image": "still image", "Text": "text",
      "Three Dimensional Object": "three dimensional object", "Software": "software, multimedia", "Mixed Material": "mixed material"
  }

  MARC = {
      'Arabic' => 'ara',
      'Chinese' => 'chi',
      'Chinese, Cantonese' => 'chi',
      'Chinese, Mandarin' => 'chi',
      'Dutch' => 'dut',
      'English' => 'eng',
      'French' => 'fre',
      'German' => 'ger',
      'Greek, modern' => 'gre',
      'Hindi' => 'hin',
      'Indonesian' => 'ind',
      'Italian' => 'ita',
      'Japanese' => 'jpn',
      'Latin' => 'lat',
      'Portuguese' =>'por',
      'Russian' => 'rus',
      'Spanish' => 'spa',
      'Turkish' => 'tur',
      'Welsh' => 'wel'
  }

  MARC_TEXT = {
      'Turkish' => 'Turkish, Ottoman',
      'Greek, modern' => 'Greek, Modern',
      'Chinese, Mandarin' => 'Chinese',
      'Chinese, Cantonese' => 'Chinese'
  }

  def self.mods_type_of_resource(title)
    title.physical_objects.collect { |p| MEDIA_TYPE_MAP[p.media_type.to_sym] }.uniq.first
  end

  def self.marc_code(lang)
    MARC[lang]
  end

  def self.marc_text(lang)
    MARC_TEXT.key?(lang) ? MARC_TEXT[lang] : lang
  end

end
