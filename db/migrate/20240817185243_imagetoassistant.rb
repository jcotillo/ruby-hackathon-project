class Imagetoassistant < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :image, :string
  end
end
