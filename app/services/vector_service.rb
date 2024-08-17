require 'openai'

class VectorService
  def initialize(api_key:, vector_store_id: 'vs_EGqkgjFL7TcoAZfr6SLLlJMM')
    @openai_client = OpenAI::Client.new(access_token: api_key)
    @vector_store_id = vector_store_id # ID of the new vector store
  end

  # Create an assistant using the vector store
  def create_assistant
    puts "Creating assistant to use vector store #{@vector_store_id}..."

    response = @openai_client.assistants.create(
      parameters: {
        model: "gpt-4o",
        name: "Complaint Search Assistant",
        description: "An assistant to search and retrieve the most relevant complaints.",
        instructions: "You are a bot that searches a vector store and returns the most relevant complaints based on the query provided.",
        tools: [
          { type: "file_search" }
        ],
        tool_resources: {
          file_search: {
            vector_store_ids: [@vector_store_id] # The vector store ID is passed here
          }
        },
        metadata: { my_internal_version_id: "1.0.0" }
      }
    )

    assistant_id = response["id"]
    puts "Assistant created with ID: #{assistant_id}"
    assistant_id
  end

  # Search for the most similar complaints using the assistant
  def search_vector_store_with_assistant(query, top_k = 5)
    assistant_id = create_assistant

    puts "Creating thread for assistant with ID #{assistant_id}..."

    # Create a thread
    thread_response = @openai_client.threads.create()
    thread_id = thread_response["id"]
    puts "Thread created with ID: #{thread_id}"

    # Add initial message from user
    message_response = @openai_client.messages.create(
      thread_id: thread_id,
      parameters: {
        role: "user",
        content: query
      }
    )
    message_id = message_response["id"]
    puts "Message added with ID: #{message_id}"

    # Log the thread ID for debugging purposes
    puts "Thread ID: #{thread_id}"

    # Retrieve the response message (optional)
    puts "Retrieving the response message..."
    response_message = @openai_client.messages.retrieve(thread_id: thread_id, id: message_id)
    puts "Response message: #{response_message['content']}"

    # Create a run using the assistant with the thread
    puts "Creating a run using the assistant..."
    run_response = @openai_client.runs.create(
      thread_id: thread_id,
      parameters: {
        assistant_id: assistant_id,
        max_prompt_tokens: 256,
        max_completion_tokens: 16,
      }
    )

    run_id = run_response['id']
    puts "run ID: #{run_id}"
    while true do
      response = @openai_client.runs.retrieve(id: run_id, thread_id: thread_id)
      status = response['status']
  
      case status
      when 'queued', 'in_progress', 'cancelling'
        puts 'Sleeping'
        sleep 1 # Wait one second and poll again
      when 'completed'
        break # Exit loop and report result to user
      when 'requires_action'
        # Handle tool calls (see below)
      when 'cancelled', 'failed', 'expired'
        puts response['last_error'].inspect
        break # or `exit`
      else
        puts "Unknown status response: #{status}"
      end
    end
   # Either retrieve all messages in bulk again, or...
    messages = @openai_client.messages.list(thread_id: thread_id, parameters: { order: 'asc' })
    puts messages
  end
end
