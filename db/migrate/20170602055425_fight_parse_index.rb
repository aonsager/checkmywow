class FightParseIndex < ActiveRecord::Migration
  def change
    create_table :fight_parse_records do |t|
      t.string   :report_id, null: false
      t.integer  :fight_id, null: false
      t.integer  :fight_guid
      t.integer  :player_id, null: false
      t.integer  :actor_id
      t.integer  :boss_id
      t.integer  :difficulty
      t.string   :player_name
      t.string   :class_type
      t.string   :spec
      t.integer  :status, default: 0
      t.integer  :version, default: 0
      t.timestamp :parsed_at
      t.timestamps
    end

    add_index :fight_parse_records, [:report_id, :fight_id, :player_id], :unique => true, :name => 'fpr_index'
  end
end