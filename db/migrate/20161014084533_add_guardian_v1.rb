class AddGuardianV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Guardian Druid', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Damage per Second</li><li>Damage Taken per Second</li><li>Self Healing per Second</li><li>External Healing per Second</li><li>Cast Efficiency</li><li>Ironfur Uptime</li><li>Thrash Uptime</li><li>Guardian of Elune Usage</li><li>Mangle! Proc Usage</li><li>Galactic Guardian Proc Usage if talented, Moonfire Uptime otherwise</li></ul><p>Resources tab:</p><ul><li>Time not Rage-Capped</li><li>Rage Gained/Wasted</li><li>Bristling Fur Effectiveness</li></ul><p>Cooldowns tab</p><ul><li>Survival Instincts Effectiveness</li><li>Rage of the Sleeper Effectiveness/Damage</li><li>Barkskin Effectiveness</li><li>Mark of Ursol Effectiveness</li><li>Frenzied Regeneration Effectiveness</li><li>Lunar Beam Healing/Damage</li></ul>');
  end
end
