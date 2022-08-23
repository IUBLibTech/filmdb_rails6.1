class CollectionPolicy < ApplicationPolicy
	def destroy?
		current_user_object.can_delete?
	end
end