class ControlledVocabulary < ApplicationRecord

  MODEL_ATTRIBUTE_FIELDS = [:title_creator_role_type, :title_publisher_role_type]
  HUMANIZED_SYMBOLS = {
      title_creator_role_type: 'Creator Role', title_publisher_role_type: 'Publisher Role',
      title_original_identifier_type: 'Original Identifier', date_type: 'Date' }

  scope :physical_object_cv, ->(medium) {

    cv = ControlledVocabulary.where(model_type: medium).select(:model_attribute, :value).order(:model_attribute, :value, :menu_index)
    cv_map(cv)
  }

  scope :title_cv, -> {
    cv = ControlledVocabulary.where(model_type: 'Title', active_status: true).select(:model_attribute, :value).order(:model_attribute, :value)
    cv_map(cv)
  }

  scope :title_date_cv, -> {
    cv = ControlledVocabulary.where(model_type: 'TitleDate', active_status: true).select(:model_attribute, :value).order(:model_attribute, :value, :menu_index)
    cv_map(cv)
  }

  scope :title_genre_cv, -> {
    cv = ControlledVocabulary.where(model_type: 'TitleGenre', active_status: true).select(:model_attribute, :value).order(:model_attribute, :value, :menu_index)
    cv_map(cv)
  }

  scope :title_form_cv, -> {
    cv = ControlledVocabulary.where(model_type: 'TitleForm', active_status: true).select(:model_attribute, :value).order(:model_attribute, :value, :menu_index)
    cv_map(cv)
  }

  scope :language_cv, -> {
    cv = ControlledVocabulary.where(model_type: 'Language', active_status: true).select(:model_attribute, :value).order(:model_attribute, :value)
    cv_map(cv)
  }

  scope :component_group_cv, -> {
    cv = ControlledVocabulary.where(model_type: 'ComponentGroup', active_status: true).select(:model_attribute, :value).order(:menu_index)
    cv_map(cv)
  }

  scope :physical_object_date_cv, -> {
    cv = ControlledVocabulary.where(model_type: 'PhysicalObjectDate', active_status: true).select(:id, :model_attribute, :value).order(:value, :menu_index)
    map = {}
    # map for these is slightly different as it should bind to the controlled vocabulary ID not copy the text :value
    cv.each do |v|
      id = v.id
      value = v.value
      sym = v.model_attribute.tr(':','').to_sym
      map[sym] = [] if map[sym].nil?
      map[sym].push [value, id]
    end
    map
  }

  scope :editable_title_cv, -> {
    ControlledVocabulary.where("model_type like 'Title%'").distinct.order(:model_attribute).pluck(:model_attribute)
  }

  def self.human_attribute_name(attribute, options = {})
    attribute = attribute.tr(':','').to_sym
    self.const_get(:HUMANIZED_SYMBOLS)[attribute] || super(attribute)
  end

  private
  def self.cv_map(scope_result)
    map = {}
    scope_result.each do |v|
      sym = v.model_attribute.tr(':', '').to_sym
      val = v.value
      map[sym] = [] if map[sym].nil?
      map[sym].push [val, val]
    end
    map
  end
end
