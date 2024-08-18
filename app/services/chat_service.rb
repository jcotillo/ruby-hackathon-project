# frozen_string_literal: true

class ChatService
  attr_accessor :client

  def initialize
    @client = OpenAI::Client.new
  end

  def create_assistant(assistant)
    response = @client.assistants.create(
      parameters: {
        model: 'gpt-4o',
        name: assistant['name'],
        description: assistant['description'],
        instructions: assistant['instructions'],
        tools: [
          { type: 'code_interpreter' },
          { type: 'file_search' }
        ],
        tool_resources: {
          code_interpreter: {
            file_ids: [] # See Files section above for how to upload files
          },
          file_search: {
            vector_store_ids: [] # See Vector Stores section above for how to add vector stores
          }
        },
        "metadata": { my_internal_version_id: '1.0.0' }
      }
    )
    response['id']
  end

  def find_assistant(assistant_id)
    @client.assistants.retrieve(id: assistant_id)
  end

  def list_assistants
    @client.assistants.list
  end

  def create_thread
    @client.threads.create
  end

  def create_run(t_id, a_id)
    @client.runs.create(thread_id: t_id,
                        parameters: {
                          assistant_id: a_id,
                          max_prompt_tokens: 2000,
                          max_completion_tokens: 10_000
                        })
  end

  def retrieve_run(run_id, t_id)
    loop do
      response = @client.runs.retrieve(id: run_id, thread_id: t_id)
      puts "run response #{response.class} ::: #{response}"

      next if response.blank?

      status = response['status']
      case status
      when 'queued', 'in_progress', 'cancelling'
        puts 'Sleeping'
        sleep 1
      when 'completed'
        return true
      when 'requires_action'
        return false
      when 'cancelled', 'failed', 'expired'
        puts response['last_error'].inspect
        return false
      else
        puts "Unknown status response: #{status}"
        return false
      end
    end
  end

  def create_message(thread_id, message)
    @client.messages.create(
      thread_id:,
      parameters: {
        role: 'user', # Required for manually created messages
        content: message
      }
    )
  end

  def get_message(thread_id, message_id)
    @client.messages.retrieve(thread_id:, id: message_id)
  end

  def list_messages(thread_id)
    @client.messages.list(thread_id:, parameters: { order: 'asc' })['data']
  end

  def delete_assistant(assistant_id)
    @client.assistants.delete(id: assistant_id)
  end

  def handle_text_file(file)
    # Logic for handling text files
  end

  def handle_image_file(file)
    # Logic for handling image files
  end

  def handle_audio_file(file)
    # Step 1: Save the file locally or to a cloud storage service
    file_path = save_file(file)

    # Step 2: Transcribe the audio to text using an external service (e.g., Whisper, Google Cloud Speech-to-Text)
    transcription = transcribe_audio(file_path)  # Pass the correct file path

    # Optionally, delete the file after processing
    File.delete(file_path) if File.exist?(file_path)

    print(transcription)
    transcription
  end

  def save_file(file)
    # Save the uploaded file to a temporary location
    file_path = Rails.root.join('tmp', 'storage', file.original_filename)
    puts(file_path)
    File.open(file_path, 'wb') do |f|
      f.write(file.read)
    end
    file_path
  end

  def transcribe_audio(file_path)
    # Here you could integrate with a service like OpenAI's Whisper or Google Cloud Speech-to-Text
    client = OpenAI::Client.new
    response = client.audio.transcribe(
      parameters: {
        model: "whisper-1",
        file: File.open(file_path, "rb"),  # Ensure the file is opened in binary mode
        response_format: "text"
      }
    )
    response['text']
  rescue StandardError => e
    Rails.logger.error("Failed to transcribe audio: #{e.message}")
    "Transcription failed."
  end
end
