class Language < ApplicationRecord
  belongs_to :physical_object

  CAPTIONS = 'Captions'
  DUBBED = 'Dubbed Dialog'
  INTERTITLES = 'Intertitles'
  ORIGINAL_DIALOG = 'Original Dialog'
  SUBTITLES = 'Subtitles'
  LANGUAGE_TYPES = [CAPTIONS, DUBBED, INTERTITLES, ORIGINAL_DIALOG, SUBTITLES]

end
