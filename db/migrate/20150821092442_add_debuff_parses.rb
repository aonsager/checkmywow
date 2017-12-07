class AddDebuffParses < ActiveRecord::Migration
  def change
    create_table :debuff_parses do |t|
      t.integer  :fight_parse_id, null: false
      t.string   :name, null: false
      t.integer  :target_id
      t.string   :target_name
      t.integer  :target_instance
      t.text     :kpi_hash, default: {}.to_yaml
      t.text     :details_hash, default: {}.to_yaml
      t.text     :uptimes_array, default: [].to_yaml
      t.text     :downtimes_array, default: [].to_yaml
      t.text     :stacks_array, default: [].to_yaml
      t.timestamps
    end

    add_index :debuff_parses, :fight_parse_id
  end
end
