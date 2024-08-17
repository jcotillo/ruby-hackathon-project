# frozen_string_literal: true

# app/controllers/dashboard/chat_controller.rb
class ChatController < ApplicationController
    before_action :authenticate_user!
    before_action :set_chat_service, only: %i[create index]

    def index
      @ai_threads = AiThread.where(user_id: current_user.id)
      @assistants = Assistant.all
      @assistant = Assistant.find_by(assistant_id: params[:assistant_id])
      @thread = AiThread.find_by(thread_id: params[:thread_id])
      @messages = @chat_service.list_messages(params[:thread_id]) if @thread&.thread_id
    end

    def list_ai_threads
      AiThread.all
    end

    def create
      @chat_service.create_message(params[:thread_id], params[:message])
      run_id = @chat_service.create_run(params[:thread_id], params[:assistant_id])['id']
      @chat_service.retrieve_run(run_id, params[:thread_id])

      redirect_back fallback_location: chat_index_path
    end

    private

    def set_chat_service
      @chat_service = ChatService.new
    end
  end
