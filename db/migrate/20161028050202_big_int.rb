class BigInt < ActiveRecord::Migration
  def change
    change_column :fight_parses, :player_id, :integer, limit: 8
    change_column :players, :player_id, :integer, limit: 8
  end
end
