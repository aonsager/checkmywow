class RestorationDruidV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Restoration Druid', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Healing Done</li><li>Cast Efficiency</li><li>Lifebloom Uptime</li><li>Rejuvenation Uptime</li><li>Mastery: Harmony Uptime</li></ul><p>Resources tab:</p><ul><li>Healing Efficiency per Mana spent</li><li>Soul of the Forest Proc Usage</li><li>Clearcasting Proc Usage</li></ul><p>Cooldowns tab</p><ul><li>Tranquility Effectiveness</li><li>Incarnation: Tree of Life Effectiveness</li></ul>');
  end
end
