# frozen_string_literal: true

class AssistantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_assistant, only: %i[show edit update destroy]
  before_action :set_chat_service, only: %i[create destroy]

  def set_chat_service
    @chat_service = ChatService.new
  end

  # GET /assistants or /assistants.json
  def index
    @assistants = Assistant.all
  end

  # GET /assistants/1 or /assistants/1.json
  def show; end

  # GET /assistants/new
  def new
    @assistant = Assistant.new
  end

  # GET /assistants/1/edit
  def edit; end

  # POST /assistants or /assistants.json
  def create
    assistant = assistant_params.to_h
    assistant['assistant_id'] = @chat_service.create_assistant(assistant)
    @assistant = Assistant.new(assistant)

    respond_to do |format|
      if @assistant.save
        format.html { redirect_to assistant_url(@assistant), notice: 'Assistant was successfully created.' }
        format.json { render :show, status: :created, location: @assistant }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @assistant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /assistants/1 or /assistants/1.json
  def update
    respond_to do |format|
      if @assistant.update(assistant_params)
        format.html { redirect_to assistant_url(@assistant), notice: 'Assistant was successfully updated.' }
        format.json { render :show, status: :ok, location: @assistant }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @assistant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /assistants/1 or /assistants/1.json
  def destroy
    @chat_service.delete_assistant(@assistant.assistant_id)
    @assistant.destroy!

    respond_to do |format|
      format.html { redirect_to assistants_url, notice: 'Assistant was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_assistant
    @assistant = Assistant.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def assistant_params
    params.require(:assistant).permit(:name, :assistant_id, :description, :instructions, :image)
  end
end
