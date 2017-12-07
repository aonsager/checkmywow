class PlayerPerformance < ActiveRecord::Migration
  def change
    create_table :report_players do |t|
      t.string   :report_id, null: false
      t.string   :player_id, null:false
      t.timestamps
    end
    add_index :report_players, [:report_id, :player_id], :unique => true

    add_column :players, :boss_counts, :string, default: {}.to_yaml
    
  end
end
