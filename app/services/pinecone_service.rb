# app/services/pinecone_service.rb
require 'faraday'
require 'json'
require 'openai'

class PineconeService
  def initialize(api_key:, index_name: 'my-complaints-index')
    @api_key = api_key
    @index_name = index_name
    @base_url = "https://#{index_name}.svc.pinecone.io"
    @connection = Faraday.new(@base_url) do |conn|
      conn.headers['Authorization'] = "Bearer #{@api_key}"
      conn.headers['Content-Type'] = 'application/json'
      conn.adapter Faraday.default_adapter
    end
    @openai_client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  # Extract and clean the "complaint_what_happened" field from the JSON data
  def clean_data(json_data)
    json_data.map do |item|
      {
        id: item['_id'] || SecureRandom.uuid, # Use the provided ID or generate a unique one
        text: item['_source']['complaint_what_happened'].strip.downcase # Clean the complaint text
      }
    end
  end

  # Generates embeddings using OpenAI's API
  def get_embeddings(texts)
    response = @openai_client.embeddings(
      parameters: { model: "text-embedding-ada-002", input: texts }
    )
    response['data'].map { |r| r['embedding'] }
  end

  # Upserts vectors into Pinecone
  def upsert_vectors(cleaned_data)
    vectors = cleaned_data.map do |item|
      embedding = get_embeddings([item[:text]]).first
      {
        id: item[:id],
        values: embedding
      }
    end

    payload = { vectors: vectors }
    @connection.post("/vectors/upsert", payload.to_json)
  end

  # Searches for similar vectors in Pinecone
  def search(query)
    query_embedding = get_embeddings([query]).first
    payload = { vector: query_embedding, topK: 5 }
    response = @connection.post("/query", payload.to_json)
    JSON.parse(response.body)
  end
end
