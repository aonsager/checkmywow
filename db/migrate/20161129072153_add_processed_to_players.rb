class AddProcessedToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :processed, :integer, default: 0
  end
end
