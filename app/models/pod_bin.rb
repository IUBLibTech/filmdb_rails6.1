class PodBin < PodObject
  self.table_name = 'bins'
  has_many :pod_physical_objects, foreign_key: 'bin_id'
end