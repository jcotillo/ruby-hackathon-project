# app/controllers/vectors_controller.rb
class VectorsController < ApplicationController
  before_action :initialize_vector_service
  skip_before_action :verify_authenticity_token, only: [:create, :search]

  def create
    json_file_path = Rails.root.join('storage', 'ruby_hackathon_data.json')

    if File.exist?(json_file_path)
      json_data = JSON.parse(File.read(json_file_path))
      @vector_service.process_and_upload_to_vector_store(json_data, "My Complaint Vector Store")
      render json: { status: 'Embeddings processed and vector store created successfully' }
    else
      render json: { error: 'JSON file not found' }, status: :not_found
    end
  end

  def search
    query = params[:query]
    
    if query.present?
      results = @vector_service.search_vector_store(query)
      render json: { results: results }
    else
      render json: { error: 'Query parameter is missing' }, status: :bad_request
    end
  end

  private

  def initialize_vector_service
    @vector_service = VectorService.new(
      api_key: ENV['OPENAI_API_KEY']
    )
  end
end
