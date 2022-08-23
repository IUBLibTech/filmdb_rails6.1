class AddBestCopyMdpiWellComponentGroupType < ActiveRecord::Migration[4.2]
  def change
    ControlledVocabulary.new(model_type: 'ComponentGroup', model_attribute: ':group_type', value: ComponentGroup::BEST_COPY_MDPI_WELLS).save
  end
end
