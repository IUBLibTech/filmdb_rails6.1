class AccompanyingDocumentation < ApplicationRecord

  belongs_to :title, optional: true
  belongs_to :series, optional: true
  has_many :physical_object_accompanying_documentations
  has_many :physical_objects, through: :physical_object_accompanying_documentations

  validates :location, presence: true
  validates :description, presence: true

  # the associated object for AD must be ONE of the follow:
  # * One or MORE Physical Objects
  # * A single Title
  # * Or a single Series
  # The only_<x>? methods are used to validate a SINGLE associated type is the only thing present
  validates :physical_objects, presence: true, if: :only_pos?
  validates :title, presence: true, if: :only_title?
  validates :series, presence: true, if: :only_series?


  def only_pos?
    physical_objects.size > 0 && title.nil? && series.nil?
  end

  def only_title?
    physical_objects.size == 0 && !title.nil? && series.nil?
  end

  def only_series?
    physical_objects.size == 0 && title.nil? && !series.nil?
  end

end
