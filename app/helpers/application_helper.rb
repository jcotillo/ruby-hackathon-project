# frozen_string_literal: true

# app/helpers/application_helper.rb
module ApplicationHelper
  def flash_class_for(flash_type)
    case flash_type.to_sym
    when :notice
      'alert-info' # or "alert-success" depending on your design
    when :alert
      'alert-warning'
    when :error
      'alert-error'
    else
      'alert-info'
    end
  end
end
