class ControlledVocabularyPolicy < ApplicationPolicy

  def index?
    current_user_object.can_add_cv?
  end
  def create?
    current_user_object.can_add_cv?
  end
end