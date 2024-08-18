json.extract! assistant, :id, :name, :description, :instructions, :created_at, :updated_at
json.url assistant_url(assistant, format: :json)
