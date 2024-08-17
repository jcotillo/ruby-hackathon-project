require 'json'
require 'openai'
require 'fileutils'

class VectorService
  def initialize(api_key:, cache_file: 'storage/embeddings_cache.json')
    @openai_client = OpenAI::Client.new(access_token: api_key)
    @cache_file = cache_file
    load_cache
  end

  # Load the cache from the file
  def load_cache
    if File.exist?(@cache_file)
      @embeddings_cache = JSON.parse(File.read(@cache_file))
      puts "Loaded existing cache from #{@cache_file}"
    else
      @embeddings_cache = {}
    end
  end

  # Save the cache to the file
  def save_cache
    FileUtils.mkdir_p(File.dirname(@cache_file)) # Ensure directory exists
    File.open(@cache_file, 'w') do |f|
      f.write(JSON.pretty_generate(@embeddings_cache))
    end
    puts "Cache saved to #{@cache_file}"
  end

  # Embed and clean multiple fields from the JSON data
  def clean_and_embed_data(json_data)
    json_data.map do |item|
      combined_text = [
        item['_source']['complaint_what_happened'],
        item['_source']['issue'],
        item['_source']['sub_product']
      ].compact.join(' ')

      embedding = get_embeddings([combined_text]).first

      {
        id: item['_id'] || SecureRandom.uuid,
        text: combined_text,
        embedding: embedding,
        category: item['_source']['issue']
      }
    end.compact
  end

  # Retrieves embeddings from the cache or generates them using OpenAI's API
  def get_embeddings(texts)
    texts.map do |text|
      if @embeddings_cache.key?(text)
        @embeddings_cache[text]
      else
        response = @openai_client.embeddings(
          parameters: { model: "text-embedding-3-small", input: [text] }
        )
        embedding = response['data'].first['embedding']
        @embeddings_cache[text] = embedding # Save to in-memory cache
        embedding
      end
    end.compact
  end

  # Save embeddings to a local JSON file
  def save_embeddings_to_file(file_path, cleaned_data)
    File.open(file_path, 'w') do |f|
      f.write(JSON.pretty_generate(cleaned_data))
    end
    puts "Embeddings saved to #{file_path}"
  end

  # Upload the JSON file containing embeddings to OpenAI's Files API
  def upload_file(file_path)
    file = File.open(file_path)
    response = @openai_client.files.upload(
      parameters: {
        purpose: "assistants", # Use a relevant purpose
        file: file
      }
    )
    file.close
    puts "File uploaded with ID: #{response['id']}"
    response['id']
  end

  # Create a vector store from the uploaded file IDs
  def create_vector_store(vector_store_name, file_ids)
    response = @openai_client.vector_stores.create(
      parameters: {
        name: vector_store_name,
        file_ids: file_ids
      }
    )
    puts "Vector store created with ID: #{response['id']}"
    response
  end

  # Full process from JSON to vector store
  def process_and_upload_to_vector_store(json_data, vector_store_name)
    cleaned_data = clean_and_embed_data(json_data)
    output_file_path = 'storage/processed_embeddings.json'
    save_embeddings_to_file(output_file_path, cleaned_data)
    save_cache

    file_id = upload_file(output_file_path)

    create_vector_store(vector_store_name, [file_id])
  end

  # Search for the most similar complaints using the vector store
  def search_vector_store(query, top_k = 5)
    query_embedding = get_embeddings([query]).first

    search_results = @vector_store.query(
      embedding: query_embedding,
      top_k: top_k
    )
    
    puts "Search results: #{search_results}"
    search_results
  end
end
