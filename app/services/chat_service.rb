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
end
