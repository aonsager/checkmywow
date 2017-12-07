class ChangeScoreIndex < ActiveRecord::Migration
  def change
    remove_index :scores, [:fight_parse_id, :score_type]
    remove_column :scores, :score_type
    remove_column :scores, :score
    add_index :scores, :fight_parse_id, :unique => true
  end
end
