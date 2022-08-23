class TitlePublisher < ApplicationRecord
  belongs_to :title
  def ==(another)
    self.class == another.class && self.name == another.name && self.publisher_type == another.publisher_type
  end
end
