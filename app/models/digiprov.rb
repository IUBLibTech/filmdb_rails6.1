class Digiprov < ApplicationRecord
  belongs_to :physical_object
  belongs_to :cage_shelf, optional: true
end
