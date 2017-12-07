class BloodV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Blood Deathknight', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Damage per Second</li><li>Damage Taken per Second</li><li>Self Healing per Second</li><li>External Healing per Second</li><li>Cast Efficiency</li><li>Bone Shield Uptime</li><li>Death Strike Casts with Ossuary</li><li>Death Strike Efficiency</li></ul><p>Resources tab:</p><ul><li>Time not Rune-Capped</li><li>Time not Runic Power-Capped</li><li>Runic Power Gained/Wasted</li><li>Blood Shield Gained/Wasted</li><li>Death and Decay Casts with Crimson Scourge Procced</li><li>Death and Decay Uptime</li><li>Blood Plague Uptime</li></ul><p>Cooldowns tab</p><ul><li>Vampiric Blood Effectiveness</li><li>Dancing Rune Weapon Effectiveness</li><li>Anti-Magic Shell Effectiveness</li><li>Consumption Effectiveness</li><li>Bonestorm Effectiveness</li><li>Blood Mirror Effectiveness</li></ul>');
  end
end
