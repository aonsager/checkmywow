class CreateHealingParse < ActiveRecord::Migration
  def change
    create_table :healing_parses do |t|
      t.string   :report_id, null: false
      t.integer  :fight_id, null: false
      t.integer  :target_id, null: false
      t.string   :target_name
      t.text     :kpi_hash, default: {}.to_yaml
      t.text     :details_hash, default: {}.to_yaml
      t.integer  :started_at
      t.integer  :ended_at
      t.timestamps
    end
    add_index :healing_parses, [:report_id, :fight_id]
  end
end
