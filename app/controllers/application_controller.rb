class ApplicationController < ActionController::Base
  def after_sign_in_path_for(_resource)
    chat_index_path
  end
end
