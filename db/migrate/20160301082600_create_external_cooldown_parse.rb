class CreateExternalCooldownParse < ActiveRecord::Migration
  def change
    create_table :external_buff_parses do |t|
      t.integer  :fight_parse_id, null: false
      t.integer  :target_id, null: false
      t.string   :target_name
      t.string   :name, null: false
      t.string   :cd_type, null: false
      t.text     :kpi_hash, default: {}.to_yaml
      t.text     :details_hash, default: {}.to_yaml
      t.integer  :started_at
      t.integer  :ended_at
      t.timestamps
    end
    add_index :external_buff_parses, [:fight_parse_id, :target_id]
  end
end
