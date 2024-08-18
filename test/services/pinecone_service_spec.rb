require 'test_helper'
require 'minitest/autorun'
require_relative '../../app/services/pinecone_service'

class PineconeServiceTest < Minitest::Test
  def setup
    @api_key = 'fake-api-key'
    @pinecone_service = PineconeService.new(api_key: @api_key)

    # Mock the Faraday connection and OpenAI client to avoid real API calls
    Faraday.stub(:new, mock_faraday_connection) do
      OpenAI::Client.stub(:new, mock_openai_client) do
        yield if block_given?
      end
    end
  end

  def test_clean_data
    json_data = [
      { '_id' => '1', '_source' => { 'complaint_what_happened' => 'Complaint 1' } },
      { '_id' => '2', '_source' => { 'complaint_what_happened' => 'Complaint 2 ' } }
    ]
    cleaned_data = @pinecone_service.clean_data(json_data)

    assert_equal '1', cleaned_data.first[:id]
    assert_equal 'complaint 1', cleaned_data.first[:text]
  end

  def test_get_embeddings
    texts = ['sample text']
    embeddings = @pinecone_service.get_embeddings(texts)

    assert_kind_of Array, embeddings
    assert_equal [0.1, 0.2, 0.3], embeddings.first
  end

  def test_upsert_vectors
    cleaned_data = [
      { id: '1', text: 'complaint 1' },
      { id: '2', text: 'complaint 2' }
    ]

    assert_silent { @pinecone_service.upsert_vectors(cleaned_data) }
  end

  def test_search
    query = 'sample query'
    mock_json_data

    results = @pinecone_service.search(query)

    assert_kind_of Array, results[:matches]
    assert_equal '1', results[:matches].first[:id]
    assert_equal 'Complaint 1', results[:matches].first[:original_data]['_source']['complaint_what_happened']
  end

  private

  def mock_faraday_connection
    mock_connection = Minitest::Mock.new
    mock_response = Minitest::Mock.new
    mock_response.expect :success?, true
    mock_response.expect :body, '{}'
    mock_connection.expect :post, mock_response, [String, String]
    mock_connection
  end

  def mock_openai_client
    mock_client = Minitest::Mock.new
    mock_client.expect :embeddings, { 'data' => [{ 'embedding' => [0.1, 0.2, 0.3] }] }, [Hash]
    mock_client
  end

  def mock_json_data
    File.stub :exist?, true do
      File.stub :read, '[{"_id": "1", "_source": {"complaint_what_happened": "Complaint 1"}}]' do
        yield if block_given?
      end
    end
  end
end
