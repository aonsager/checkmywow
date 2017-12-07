class AddStatusToFightParse < ActiveRecord::Migration
  def change
    add_column :fight_parses, :status, :integer, :default => 0
  end
end
