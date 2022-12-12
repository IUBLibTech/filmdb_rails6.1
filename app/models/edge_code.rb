class EdgeCode < ApplicationRecord
  belongs_to :physical_object, optional: true
end
