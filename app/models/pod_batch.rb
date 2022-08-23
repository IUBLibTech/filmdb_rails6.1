class PodBatch < PodObject
  self.table_name = 'batches'
  has_many :pod_bins, foreign_key: 'batch_id'
end