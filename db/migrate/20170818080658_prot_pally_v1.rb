class ProtPallyV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Affliction Warlock', version: 1).update_attributes(content: '<p>Basic</p><ul><li>Damage taken</li><li>Self healing</li><li>External Healing</li><li>Light of the Protector healing</li></ul><p>Cast Efficiency</p><p>Resources</p><ul><li>Casts per minute</li><li>Shield of the Righteous uptime</li><li>Consecration uptime</li><li>Blessed Hammer uptime</li></ul><p>Cooldowns<p><ul><li>Eye of Tyr damage reduction</li><li>Ardent Defender damage reduction</li><li>Guardian of Ancient Kings damage reduction</li><li>Avenging Wrath damage/healing increase</li></ul>', patch: '7.2.5');
  end
end
