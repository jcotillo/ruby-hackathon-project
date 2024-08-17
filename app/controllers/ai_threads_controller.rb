# frozen_string_literal: true

class AiThreadsController < ApplicationController
  before_action :authenticate_user!

  def create
    thread = {
      thread_id: ChatService.new.create_thread['id'],
      name: 'New Complaint',
      user_id: current_user.id
    }

    AiThread.create(thread)
    redirect_back fallback_location: chat_index_path
  end

  def update
    @thread = AiThread.find_by(id: params[:id])
    @thread.update(thread_params)

    redirect_back fallback_location: chat_index_path
  end

  def destroy
    AiThread.find_by(id: params[:id]).destroy

    redirect_back fallback_location: chat_index_path
  end

  private

  def thread_params
    params.require(:ai_thread).permit(:name)
  end
end
