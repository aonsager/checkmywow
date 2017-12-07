class ElementalShamanV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Elemental Shaman', version: 1).update_attributes(content: '<p>Basic tab:</p><ul><li>Lava Burst casts</li><li>Flame Shock uptime</li></ul><p>Resources tab:</p><ul><li>Lightning Shield charges</li><li>Elemental Blast casts</li><li>Unleashed Fury casts</li></ul><p>Cooldowns tab</p><ul><li>Ascendance damage</li><li>Elemental Mastery damage</li><li>Liquid Magma damage</li><li>Earthquake damage</li><li>Nithramus damage</li></ul>');
  end
end
