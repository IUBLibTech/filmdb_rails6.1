json.array!(@physical_objects) do |physical_object|
  json.extract! physical_object, :id
  json.url physical_object_url(physical_object, format: :json)
end
