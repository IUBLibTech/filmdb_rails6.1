class TitleForm < ApplicationRecord
  belongs_to :title
  def ==(another)
    self.class == another.class && self.form == another.form
  end
end
