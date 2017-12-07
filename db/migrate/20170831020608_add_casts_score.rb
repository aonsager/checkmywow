class AddCastsScore < ActiveRecord::Migration
  def change
    add_column :fight_parses, :casts_score, :integer
  end
end
