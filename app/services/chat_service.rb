# frozen_string_literal: true

require 'roo'
require 'pdf-reader'
require 'docx'

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
                          max_prompt_tokens: 10_000,
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
      when 'incomplete'
        Rails.logger.warn("The operation did not complete successfully. Status: #{status}")
        return false
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
        role: 'user',
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
    file_path = save_file(file)
    content = extract_text_from_file(file_path)
    content
  end

  def extract_text_from_file(file_path)
    case File.extname(file_path).downcase
    when '.pdf', '.txt'
      extract_text_from_pdf(file_path)
    when '.csv', '.xlsx', '.ods'
      extract_text_from_spreadsheet(file_path)
    when '.docx'
      extract_text_from_docx(file_path)
    else
      File.read(file_path)
    end
  end

  def extract_text_from_pdf(file_path)
    reader = PDF::Reader.new(file_path)
    reader.pages.map(&:text).join("\n")
  rescue StandardError => e
    Rails.logger.error("Failed to extract text from PDF: #{e.message}")
    "Text extraction failed."
  end

  def extract_text_from_spreadsheet(file_path)
    spreadsheet = Roo::Spreadsheet.open(file_path)
    sheet = spreadsheet.sheet(0)
    sheet.each_row_streaming.map do |row|
      row.map(&:value).join(", ")
    end.join("\n")
  rescue StandardError => e
    Rails.logger.error("Failed to extract text from spreadsheet: #{e.message}")
    "Text extraction failed."
  end

  def extract_text_from_docx(file_path)
    begin
      unless File.exist?(file_path)
        Rails.logger.error("File not found: #{file_path}")
        return "Text extraction failed: file not found."
      end

      doc = Docx::Document.open(file_path)
      text = doc.paragraphs.map(&:to_s).join("\n")
    rescue StandardError => e
      Rails.logger.error("Failed to open DOCX file: #{file_path}")
      Rails.logger.error("Error details: #{e.message}")
      text = "Text extraction failed."
    end
    text
  end

  def handle_image_file(file)
    # Logic for handling image files
  end

  def handle_audio_file(file)
    file_path = save_file(file)
    transcription = transcribe_audio(file_path)
    File.delete(file_path) if File.exist?(file_path)
    transcription
  end

  def save_file(file)
    file_path = Rails.root.join('tmp', 'storage', file.original_filename)
    File.open(file_path, 'wb') do |f|
      f.write(file.read)
    end
    file_path
  end

  def transcribe_audio(file_path)
    client = OpenAI::Client.new
    response = client.audio.transcribe(
      parameters: {
        model: "whisper-1",
        file: File.open(file_path, "rb"),
        response_format: "text"
      }
    )
    response['text']
  rescue StandardError => e
    Rails.logger.error("Failed to transcribe audio: #{e.message}")
    "Transcription failed."
  end
end
