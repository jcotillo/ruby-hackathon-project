class Createruns < ActiveRecord::Migration[7.1]
  def change
    create_table :runs do |t|
      t.string :run_id
      t.string :assistant_id
      t.string :thread_id

      t.timestamps
    end
  end
end
