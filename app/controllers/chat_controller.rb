# frozen_string_literal: true

# app/controllers/dashboard/chat_controller.rb

class ChatController < ApplicationController
    before_action :authenticate_user!
    before_action :set_chat_service, only: %i[create index]

    FILE_TYPES = {
          text: ['txt', 'md', 'doc', 'pdf', 'docx'],
          image: ['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'],
          audio: ['mp3', 'wav', 'ogg']
        }
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
      if params[:file]
        file = params[:file]
        transcription = @chat_service.handle_audio_file(file)

        # Use the transcription as the message if it is not empty or nil
        if transcription.present?
          @chat_service.create_message(params[:thread_id], transcription)
        else
          flash[:error] = "Transcription failed or returned an empty result."
          redirect_back fallback_location: chat_index_path and return
        end
      elsif params[:message].present?
        @chat_service.create_message(params[:thread_id], params[:message])
      else
        flash[:error] = "Message or file must be provided."
        redirect_back fallback_location: chat_index_path and return
      end

      run_id = @chat_service.create_run(params[:thread_id], params[:assistant_id])['id']
      @chat_service.retrieve_run(run_id, params[:thread_id])

      redirect_back fallback_location: chat_index_path
    end

    private

    def set_chat_service
      @chat_service = ChatService.new
    end
  end
