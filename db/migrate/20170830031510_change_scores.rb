class ChangeScores < ActiveRecord::Migration
  def change
    add_column :scores, :player_name, :string
    add_column :scores, :scores_hash, :string, default: {}.to_yaml
  end
end
