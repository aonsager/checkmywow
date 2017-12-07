class AddFightParses < ActiveRecord::Migration
  def change
    create_table :fight_parses do |t|
      t.string   :report_id, null: false
      t.integer  :fight_id, null: false
      t.integer  :player_id, null: false
      t.string   :player_name
      t.string   :class_type
      t.string   :spec
      t.integer  :boss_id
      t.integer  :difficulty
      t.boolean  :kill
      t.boolean  :processed
      t.integer  :version, default: 1
      t.text     :kpi_hash, default: {}.to_yaml
      t.text     :resources_hash, default: {}.to_yaml
      t.text     :cooldowns_hash, default: {}.to_yaml
      t.datetime :report_started_at
      t.integer  :started_at
      t.integer  :ended_at
      t.timestamps
    end

    create_table :cooldown_parses do |t|
      t.integer  :fight_parse_id, null: false
      t.string   :name, null: false
      t.string   :cd_type, null: false
      t.text     :kpi_hash, default: {}.to_yaml
      t.text     :details_hash, default: {}.to_yaml
      t.integer  :started_at
      t.integer  :ended_at
      t.timestamps
    end

    add_index :fight_parses, [:report_id, :fight_id, :player_id], :unique => true
    add_index :cooldown_parses, :fight_parse_id
  end
end