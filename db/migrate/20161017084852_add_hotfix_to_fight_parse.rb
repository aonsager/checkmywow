class AddHotfixToFightParse < ActiveRecord::Migration
  def change
    add_column :fight_parses, :hotfix, :integer, default: 0
  end
end
