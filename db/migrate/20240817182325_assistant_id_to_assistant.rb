class AssistantIdToAssistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :assistant_id, :string
  end
end
