class VectorsController < ApplicationController
  before_action :initialize_pinecone
  skip_before_action :verify_authenticity_token, only: [:create, :search]

  def create
    # Read JSON data from the file
    json_file_path = Rails.root.join('storage', 'ruby_hackathon_data.json')
    
    if File.exist?(json_file_path)
      json_data = JSON.parse(File.read(json_file_path))
      cleaned_data = @pinecone_service.clean_data(json_data)
      @pinecone_service.upsert_vectors(cleaned_data)
      render json: { status: 'Vectors upserted successfully' }
    else
      render json: { error: 'JSON file not found' }, status: :not_found
    end
  end

  def search
    query = params[:query]
    results = @pinecone_service.search(query)
    render json: results
  end

  private

  def initialize_pinecone
    @pinecone_service = PineconeService.new(
      api_key: ENV['PINECONE_API_KEY']
    )
  end
end
