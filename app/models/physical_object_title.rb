class PhysicalObjectTitle < ApplicationRecord
  belongs_to :physical_object
  belongs_to :title

	# Any validation on this object that includes physical object id fails whenever a new physical object is created, why?...
	validates :title_id, presence: true
  #validates :physical_object_id, presence: true
  #validates :title_id, uniqueness: { scope: :physical_object_id }
end
