class EnhancementShamanV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Enhancement Shaman', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Damage Done</li><li>Cast Efficiency</li><li>Buff Uptime (Landslide/Boulderfist, Frostbrand)</li><li>Stormbringer Proc Usage</li></ul><p>Resources tab:</p><ul><li>Maelstrom Gained</li><li>Maelstrom Usage</li></ul><p>Cooldowns tab</p><ul><li>Doom Winds Effectiveness</li><li>Feral Spirit Effectiveness</li><li>Ascendance Effectiveness</li></ul>');
  end
end
