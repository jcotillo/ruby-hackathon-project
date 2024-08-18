# app/services/pinecone_service.rb
require 'faraday'
require 'json'
require 'openai'

class PineconeService
  def initialize(api_key:)
    @api_key = api_key
    @base_url = "https://my-complaints-index-ozhupb3.svc.aped-4627-b74a.pinecone.io"
    @connection = Faraday.new(@base_url) do |conn|
      conn.headers['Api-Key'] = @api_key
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

  # Upserts vectors into Pinecone with batching to avoid exceeding payload size limits
  def upsert_vectors(cleaned_data)
    puts "upserting vectors.."
    vectors = cleaned_data.map do |item|
      embedding = get_embeddings([item[:text]]).first
      {
        id: item[:id],
        values: embedding
      }
    end
    puts "passing embeddings..."
    # Batch the vectors to ensure each request stays within Pinecone's size limits
    vectors.each_slice(100) do |vector_batch| # Adjust batch size as needed
      payload = { vectors: vector_batch }
      response = @connection.post("/vectors/upsert", payload.to_json)

      if response.success?
        puts "Batch upserted successfully."
      else
        raise "Failed to upsert batch: #{response.status} - #{response.body}"
      end
    end
  end

  def search(query)
    query_embedding = get_embeddings([query]).first
    payload = {
      vector: query_embedding,
      topK: 5,
      includeValues: true, # Include the original vectors in the search result
      includeMetadata: true # Include metadata to help identify the vectors
    }
    response = @connection.post("/query", payload.to_json)
  
    if response.success?
      search_results = JSON.parse(response.body)
  
      # Load the original JSON data to map the IDs back to the original data
      json_file_path = Rails.root.join('storage', 'ruby_hackathon_data.json')
      json_data = JSON.parse(File.read(json_file_path)) if File.exist?(json_file_path)
  
      # Enrich the search results with the actual values from the JSON data
      enriched_matches = search_results['matches'].map do |match|
        original_data = json_data.find { |item| item['_id'] == match['id'] }
        {
          id: match['id'],
          score: match['score'],
          original_data: original_data # Adding the original data to the match result
        }
      end
  
      { results: search_results['results'], matches: enriched_matches }
    else
      raise "Search failed: #{response.status} - #{response.body}"
    end
  end  
end
