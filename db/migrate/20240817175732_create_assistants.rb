class CreateAssistants < ActiveRecord::Migration[7.1]
  def change
    create_table :assistants do |t|
      t.string :name
      t.text :description
      t.text :instructions

      t.timestamps
    end
  end
end
