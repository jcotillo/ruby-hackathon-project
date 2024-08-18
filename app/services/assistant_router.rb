require 'openai'

class AssistantRouter
  ASSISTANT_TYPES = {
    text: ['txt', 'md', 'doc', 'pdf', 'docx'],
    image: ['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'],
    audio: ['flac', 'm4a', 'mp3', 'mp4', 'mpeg', 'mpga', 'oga', 'ogg', 'wav', 'webm']
  }

  def initialize
    api_key = ENV['OPENAI_ACCESS_TOKEN']
    raise "OPENAI_ACCESS_TOKEN environment variable is not set" if api_key.nil? || api_key.empty?

    @client = OpenAI::Client.new(access_token: api_key)
    @assistants = {}
    load_assistants
  end

  def route_file(file_path)
    file_extension = File.extname(file_path).delete('.').downcase
    assistant_type = get_assistant_type(file_extension)

    if assistant_type
      content = File.binread(file_path)
      process_with_assistant(assistant_type, content)
    else
      { error: "Unsupported file type: #{file_extension}" }
    end
  end

  def route_text(content)
    process_with_assistant(:text, content)
  end

  private

  def load_assistants
    @client.assistants.list['data'].each do |assistant|
      @assistants[assistant['name']] = assistant['id']
    end

    create_missing_assistants
  end

  def create_missing_assistants
    ASSISTANT_TYPES.keys.each do |type|
      next if @assistants.key?(type.to_s)

      new_assistant = @client.assistants.create(
        name: type.to_s,
        instructions: "You are a #{type} processing assistant.",
        model: "gpt-4-0125-preview"
      )
      @assistants[type.to_s] = new_assistant['id']
    end
  end

  def get_assistant_type(file_extension)
    ASSISTANT_TYPES.find { |type, extensions| extensions.include?(file_extension) }&.first
  end

  def process_with_assistant(assistant_type, content)
    assistant_id = @assistants[assistant_type.to_s]

    thread = @client.threads.create
    message = @client.messages.create(
      thread_id: thread.id,
      role: 'user',
      content: content
    )

    run = @client.runs.create(
      thread_id: thread.id,
      assistant_id: assistant_id
    )

    # Wait for the run to complete
    while ['queued', 'in_progress'].include?(run.status)
      sleep(1)
      run = @client.runs.retrieve(thread_id: thread.id, id: run.id)
    end

    if run.status == 'completed'
      messages = @client.messages.list(thread_id: thread.id)
      assistant_message = messages.data.find { |msg| msg.role == 'assistant' }

      {
        assistant_type: assistant_type,
        assistant_id: assistant_id,
        response: assistant_message.content.first.text.value
      }
    else
      { error: "Run failed with status: #{run.status}" }
    end
  end
end
