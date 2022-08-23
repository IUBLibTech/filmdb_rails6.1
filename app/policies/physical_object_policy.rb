class PhysicalObjectPolicy < ApplicationPolicy
	def destroy?
		current_user_object.can_delete?
	end

	def update_location?
		current_user_object.can_update_physical_object_location?
	end
end