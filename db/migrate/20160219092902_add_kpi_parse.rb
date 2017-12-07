class AddKpiParse < ActiveRecord::Migration
  def change
    create_table :kpi_parses do |t|
      t.integer  :fight_parse_id, null: false
      t.string   :name, null: false
      t.text     :kpi_hash, default: {}.to_yaml
      t.text     :details_hash, default: {}.to_yaml
      t.timestamps
    end

    add_index :kpi_parses, :fight_parse_id
  end
end
