# app/controllers/vectors_controller.rb
class VectorsController < ApplicationController
  before_action :initialize_vector_service
  skip_before_action :verify_authenticity_token, only: [:search]

  def search
    query = params[:query] || "I am having issues with my store credit card and late fees."

    if query.present?
      results = @vector_service.search_vector_store_with_assistant(query)
      render json: { results: results }
    else
      render json: { error: 'Query parameter is missing' }, status: :bad_request
    end
  end

  private

  def initialize_vector_service
    @vector_service = VectorService.new(
      api_key: ENV['OPENAI_API_KEY'],
      vector_store_id: 'vs_EGqkgjFL7TcoAZfr6SLLIJMM' # Use the new vector store ID
    )
  end
end
