class BeastmasteryV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Beastmastery Hunter', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Damage Done</li><li>Cast Efficiency</li><li>Wild Call Proc Usage</li><li>Titan\'s Thunder Usage</li></ul><p>Resources tab:</p><ul><li>Time not Focus-Capped</li><li>Focus Gained/Wasted</li></ul><p>Cooldowns tab</p><ul><li>Bestial Wrath Effectiveness</li><li>Killer Cobra Effectiveness</li><li>Aspect of the Wild Effectiveness</li><li>Titan\'s Thunder Effectiveness</li><li>A Murder of Crows Effectiveness</li><li>Barrage Effectiveness</li><li>Stampede Effectiveness</li></ul>');
  end
end
