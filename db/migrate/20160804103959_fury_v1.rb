class FuryV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Fury Warrior', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Cast Efficiency</li><li>Enrage Uptime</li><li>Raging Blow Damage</li><li>Execute Damage</li></ul><p>Resources tab:</p><ul><li>Time not Fury-Capped</li><li>Meat Cleaver Proc Usage</li></ul><p>Cooldowns tab</p><ul><li>Thorasus Effectiveness</li><li>Battle Cry Effectiveness</li><li>Avatar Effectiveness</li><li>Bladestorm Effectiveness</li><li>Dragon Roar Effectiveness</li></ul>');
  end
end
