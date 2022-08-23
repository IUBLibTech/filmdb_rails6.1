class AddBestCopyAndMdpiComponentGroupTypes < ActiveRecord::Migration[4.2]
  def change
    ['Best Copy', 'Best Copy (MDPI)', 'Reformatting (MDPI)', 'Reformatting Replacement (MDPI)'].each do |cgt|
      ControlledVocabulary.new(model_type: 'ComponentGroup', model_attribute: ':group_type', value: cgt).save
    end
  end
end
