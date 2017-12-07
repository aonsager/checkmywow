class ElementalV < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Elemental Shaman', version: 1).update_attributes(content: '<p>Key Metrics:</p><ul><li>Damage Done</li><li>Cast Efficiency</li><li>Flameshock Uptime</li><li>Lava Burst Usage</li><li>Stormkeeper Usage</li><li>Chain Lightning Usage</li></ul><p>Resources tab:</p><ul><li>Maelstrom Gained</li><li>Maelstrom Usage</li><li>Earth Shock Usage</li><li>Totem Mastery Uptime</li><li>Always Be Casting</li></ul><p>Cooldowns tab</p><ul><li>Fire/Storm Elemental Effectiveness</li><li>Stormkeeper Effectiveness</li><li>Ascendance Effectiveness</li></ul>');
  end
end
