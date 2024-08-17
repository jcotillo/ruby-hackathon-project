class AddIdToAiThreads < ActiveRecord::Migration[7.1]
  def change
    add_column :ai_threads, :user_id, :integer, null: false
    add_index :ai_threads, :user_id
  end
end
