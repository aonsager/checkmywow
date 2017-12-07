class AddBossPercentageToFights < ActiveRecord::Migration
  def change
    add_column :fights, :boss_percent, :integer, :default => 0
  end
end
