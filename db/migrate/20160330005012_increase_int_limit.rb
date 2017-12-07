class IncreaseIntLimit < ActiveRecord::Migration
  def change
    change_column :fights, :started_at, :integer, limit: 8
    change_column :fights, :ended_at, :integer, limit: 8
    change_column :fight_parses, :started_at, :integer, limit: 8
    change_column :fight_parses, :ended_at, :integer, limit: 8
    change_column :cooldown_parses, :started_at, :integer, limit: 8
    change_column :cooldown_parses, :ended_at, :integer, limit: 8
    change_column :external_buff_parses, :started_at, :integer, limit: 8
    change_column :external_buff_parses, :ended_at, :integer, limit: 8
  end
end
