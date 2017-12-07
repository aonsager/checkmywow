class Fix20170818 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Protection Paladin', version: 1).update_attributes(content: '<p>Basic</p><ul><li>Damage taken</li><li>Self healing</li><li>External Healing</li><li>Light of the Protector healing</li></ul><p>Cast Efficiency</p><p>Resources</p><ul><li>Casts per minute</li><li>Shield of the Righteous uptime</li><li>Consecration uptime</li><li>Blessed Hammer uptime</li></ul><p>Cooldowns<p><ul><li>Eye of Tyr damage reduction</li><li>Ardent Defender damage reduction</li><li>Guardian of Ancient Kings damage reduction</li><li>Avenging Wrath damage/healing increase</li></ul>', patch: '7.2.5');
    Changelog.find_or_create_by(fp_type: 'Affliction Warlock', version: 1).update_attributes(content: '<p>Basic</p><ul><li>Agony uptime</li><li>Corruption uptime</li><li>Unstable Affliction uptime</li></ul><p>Cast Efficiency</p><p>Resources</p><ul><li>Soulshards gained/wasted</li><li>Always be casting</li></ul><p>Cooldowns<p><ul><li>Soul Harvest damage</li><li>Tormented Souls damage</li><li>Unstable Affliction damage</li><li>Drain Soul usage during Unstable Affliction</li></ul>', patch: '7.2.5');
  end
end
