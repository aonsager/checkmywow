class AddCombatantinfoToFightParse < ActiveRecord::Migration
  def change
    add_column :fight_parses, :combatant_info, :text, default: {}.to_yaml
  end
end
