class Modification < ApplicationRecord
  belongs_to :user, optional: true
end
