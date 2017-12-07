class SubtletyRogueV1 < ActiveRecord::Migration
  def change
    Changelog.find_or_create_by(fp_type: 'Subtlety Rogue', version: 1).update_attributes(content: '<p>Basic tab:</p><ul><li>Slice and Dice uptime</li><li>Rupture uptime</li></ul><p>Resources tab:</p><ul><li>Energy pooled when major cooldowns were used:</li><ul><li>Stealth / Vanish</li><li>Shadow Dance</li><li>Shadow Reflection</li></ul></ul><p>Cooldowns tab</p><ul><li>Maalus Damage</li><li>Soul Capacitor Damage</li><li>Stealth / Vanish Damage</li><li>Shadow Dance Damage</li><li>Shadow Reflection Damage</li></ul>');
  end
end
