class AddCastsToFightParses < ActiveRecord::Migration
  def change
    add_column :fight_parses, :casts_hash, :text, :default => {}.to_yaml
  end
end
