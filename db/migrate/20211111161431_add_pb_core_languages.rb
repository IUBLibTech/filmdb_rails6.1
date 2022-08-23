class AddPbCoreLanguages < ActiveRecord::Migration[4.2]
  require 'csv'
  EXISTING = ["Arabic","Chinese","English","French","German","Hindi","Italian","Japanese","Portuguese","Russian","Spanish","Sudanese","Greek, modern","Dutch","Indonesian","Welsh","Latin","Chinese, Mandarin","Chinese, Cantonese","Turkish"]
  def up
    ControlledVocabulary.transaction do
      begin
        f = Rails.root+"tmp/pbcore_langs.csv"
        raise ManualRollBackError("Missing tmp/pbcore_langs.csv file") unless File.exists? f
        l = CSV.read(f).flatten
        l.each do |lang|
          unless EXISTING.include?(lang) || ControlledVocabulary.exists?(model_type: "Language", value: lang)
            ControlledVocabulary.new(model_type: "Language", model_attribute: ":language", value: lang).save
          end
        end
      end
    end
  end

  def down
    ControlledVocabulary.where("model_type = 'Language' and model_attribute = ':language' and value not in (?)", EXISTING).delete_all
  end

end
