class UserPolicy < ApplicationPolicy

	def index?
		current_user_object.can_edit_users?
	end

	def new?
		current_user_object.can_edit_users?
	end

	def create?
		current_user_object.can_edit_users?
	end

	def edit?
		current_user_object.can_edit_users?
	end

	def update?
		current_user_object.can_edit_users?
	end

	def show?
		current_user_object.can_edit_users?
	end

	def destroy?
		current_user_object.can_edit_users?
	end

	def can_delete_objects?
		current_user_object.can_delete?
	end

  def can_add_cv?
		current_user_object.can_add_cv?
	end

  def can_edit_users?
		current_user_object.can_edit_users?
	end

end