class AddScores < ActiveRecord::Migration
  def change
    create_table :scores do |t|
      t.integer  :fight_parse_id, null: false
      t.string   :report_id
      t.integer  :fight_id
      t.integer  :player_id, limit: 8
      t.string   :spec
      t.string   :score_type
      t.integer  :boss_id
      t.integer  :difficulty
      t.integer  :fight_length
      t.integer  :score
      t.timestamps
    end

    add_index :scores, [:fight_parse_id, :score_type], :unique => true
  end
end
