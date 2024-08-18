# frozen_string_literal: true

class AiThread < ApplicationRecord
  belongs_to :user
  validates :thread_id, presence: true, uniqueness: true
end
