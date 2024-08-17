class AiThreads < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_threads do |t|
      t.string :name
      t.string :thread_id

      t.timestamps
    end
  end
end
