json.array!(@controlled_vocabularies) do |controlled_vocabulary|
  json.extract! controlled_vocabulary, :id
  json.url controlled_vocabulary_url(controlled_vocabulary, format: :json)
end
