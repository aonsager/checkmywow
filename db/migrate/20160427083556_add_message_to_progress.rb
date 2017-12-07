class AddMessageToProgress < ActiveRecord::Migration
  def change
    add_column :progresses, :message, :string
  end
end
